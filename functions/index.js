const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Validate Mercado Pago webhook signature (x-signature header).
 * See: https://www.mercadopago.com.br/developers/en/docs/your-integrations/notifications/webhooks
 */
function validateMpSignature(req) {
  const xSignature = req.headers["x-signature"];
  const xRequestId = req.headers["x-request-id"];

  if (!xSignature || !xRequestId) return false;

  const secret = functions.config().mercadopago?.webhook_secret;
  if (!secret) {
    console.warn("mercadopago.webhook_secret not configured - skipping signature validation");
    return true; // allow in dev when secret is not set
  }

  // Parse x-signature: "ts=...,v1=..."
  const parts = {};
  xSignature.split(",").forEach((part) => {
    const [key, value] = part.split("=");
    parts[key.trim()] = value.trim();
  });

  const ts = parts["ts"];
  const v1 = parts["v1"];

  if (!ts || !v1) return false;

  const dataId = req.query["data.id"] || req.body?.data?.id || "";
  const manifest = `id:${dataId};request-id:${xRequestId};ts:${ts};`;

  const hmac = crypto.createHmac("sha256", secret);
  hmac.update(manifest);
  const generated = hmac.digest("hex");

  return generated === v1;
}

/**
 * Map Mercado Pago preapproval status to our internal status.
 */
function mapMpStatus(mpStatus) {
  const statusMap = {
    authorized: "ativo",
    paused: "pausado",
    cancelled: "cancelado",
    pending: "pendente",
  };
  return statusMap[mpStatus] || mpStatus;
}

/**
 * Look up an assinatura document by its mpSubscriptionId across all barbearias.
 * Returns { ref, data, barbeariaId } or null.
 */
async function findAssinaturaByMpId(mpSubscriptionId) {
  const barbearias = await db.collection("barbearias").get();

  for (const barbearia of barbearias.docs) {
    const snap = await db
      .collection("barbearias")
      .doc(barbearia.id)
      .collection("assinaturas")
      .where("mp_subscription_id", "==", mpSubscriptionId)
      .limit(1)
      .get();

    if (!snap.empty) {
      const doc = snap.docs[0];
      return { ref: doc.ref, data: doc.data(), barbeariaId: barbearia.id };
    }
  }
  return null;
}

/**
 * Send an FCM notification to a user by looking up their fcmToken.
 */
async function sendNotificationToUser(barbeariaId, firebaseUid, title, body) {
  if (!firebaseUid) return;

  const userDoc = await db
    .collection("barbearias")
    .doc(barbeariaId)
    .collection("usuarios")
    .doc(firebaseUid)
    .get();

  if (!userDoc.exists) return;

  const userData = userDoc.data();
  const token = userData.fcm_token;

  if (!token) {
    console.log(`No FCM token for user ${firebaseUid} in barbearia ${barbeariaId}`);
    return;
  }

  try {
    await messaging.send({
      token,
      notification: { title, body },
      android: { priority: "high" },
    });
    console.log(`Notification sent to ${firebaseUid}: ${title}`);
  } catch (err) {
    // Token may be stale - remove it so we don't keep failing
    if (
      err.code === "messaging/invalid-registration-token" ||
      err.code === "messaging/registration-token-not-registered"
    ) {
      console.log(`Removing stale FCM token for user ${firebaseUid}`);
      await userDoc.ref.update({ fcm_token: admin.firestore.FieldValue.delete() });
    } else {
      console.error("FCM send error:", err);
    }
  }
}

/**
 * Find all admin users of a barbearia and send them a notification.
 */
async function notifyAdmins(barbeariaId, title, body) {
  const adminsSnap = await db
    .collection("barbearias")
    .doc(barbeariaId)
    .collection("usuarios")
    .where("role", "==", "admin")
    .where("ativo", "==", true)
    .get();

  const promises = adminsSnap.docs.map((doc) =>
    sendNotificationToUser(barbeariaId, doc.id, title, body)
  );
  await Promise.all(promises);
}

// ---------------------------------------------------------------------------
// 1. Mercado Pago Webhook (HTTP)
// ---------------------------------------------------------------------------

exports.mpWebhook = functions.https.onRequest(async (req, res) => {
  // Only accept POST
  if (req.method !== "POST") {
    return res.status(405).send("Method not allowed");
  }

  // Validate signature
  if (!validateMpSignature(req)) {
    console.error("Invalid Mercado Pago webhook signature");
    return res.status(401).send("Unauthorized");
  }

  const { type, data, action } = req.body;

  // We only care about subscription (preapproval) events
  if (type !== "subscription_preapproval") {
    console.log(`Ignoring webhook type: ${type}`);
    return res.status(200).send("OK");
  }

  const mpSubscriptionId = data?.id;
  if (!mpSubscriptionId) {
    console.error("No subscription ID in webhook payload");
    return res.status(400).send("Missing subscription ID");
  }

  console.log(`Processing MP webhook: action=${action}, subscriptionId=${mpSubscriptionId}`);

  try {
    // Fetch subscription details from Mercado Pago API
    const mpAccessToken = functions.config().mercadopago?.access_token;
    let mpStatus = null;

    if (mpAccessToken) {
      const { MercadoPagoConfig, PreApproval } = require("mercadopago");
      const client = new MercadoPagoConfig({ accessToken: mpAccessToken });
      const preapproval = new PreApproval(client);

      const subscription = await preapproval.get({ id: mpSubscriptionId });
      mpStatus = subscription.status;
    } else {
      // Infer status from the action field
      const actionMap = {
        "updated": null, // need to check MP API for actual status
        "created": "authorized",
      };
      mpStatus = actionMap[action];
      console.warn("No MP access_token configured - cannot fetch subscription status");
    }

    if (!mpStatus) {
      console.log("Could not determine subscription status, acknowledging webhook");
      return res.status(200).send("OK");
    }

    // Find the assinatura in Firestore and update it
    const result = await findAssinaturaByMpId(mpSubscriptionId);

    if (!result) {
      console.warn(`No assinatura found for MP subscription ${mpSubscriptionId}`);
      return res.status(200).send("OK");
    }

    const newStatus = mapMpStatus(mpStatus);
    const updateData = {
      status: newStatus,
      mp_last_webhook_at: admin.firestore.FieldValue.serverTimestamp(),
    };

    await result.ref.update(updateData);
    console.log(
      `Updated assinatura ${result.ref.id} in barbearia ${result.barbeariaId}: status -> ${newStatus}`
    );

    // Notify admins about subscription status change
    await notifyAdmins(
      result.barbeariaId,
      "Assinatura atualizada",
      `Status da assinatura alterado para: ${newStatus}`
    );

    return res.status(200).send("OK");
  } catch (err) {
    console.error("Error processing MP webhook:", err);
    return res.status(500).send("Internal error");
  }
});

// ---------------------------------------------------------------------------
// 2. Send Agendamento Reminders (Scheduled - every 30 min)
// ---------------------------------------------------------------------------

exports.sendAgendamentoReminder = functions.pubsub
  .schedule("every 30 minutes")
  .timeZone("America/Sao_Paulo")
  .onRun(async (_context) => {
    const now = new Date();
    const oneHourFromNow = new Date(now.getTime() + 60 * 60 * 1000);

    const barbearias = await db.collection("barbearias").get();

    for (const barbearia of barbearias.docs) {
      const barbeariaId = barbearia.id;

      // Query appointments starting in the next hour that haven't been reminded
      const agendamentos = await db
        .collection("barbearias")
        .doc(barbeariaId)
        .collection("agendamentos")
        .where("data_hora_inicio", ">=", now.toISOString())
        .where("data_hora_inicio", "<=", oneHourFromNow.toISOString())
        .where("status", "in", ["pendente", "confirmado"])
        .get();

      for (const agDoc of agendamentos.docs) {
        const ag = agDoc.data();

        // Skip if reminder was already sent
        if (ag.lembrete_enviado) continue;

        // Find the barbeiro user doc by barbeiro_id
        const barbeirosSnap = await db
          .collection("barbearias")
          .doc(barbeariaId)
          .collection("usuarios")
          .where("role", "==", "barbeiro")
          .where("ativo", "==", true)
          .get();

        // Look up client name for a better notification message
        let clienteNome = "Cliente";
        if (ag.cliente_id) {
          const clientesSnap = await db
            .collection("barbearias")
            .doc(barbeariaId)
            .collection("clientes")
            .where("id", "==", ag.cliente_id)
            .limit(1)
            .get();

          if (!clientesSnap.empty) {
            clienteNome = clientesSnap.docs[0].data().nome || "Cliente";
          }
        }

        const horaInicio = new Date(ag.data_hora_inicio);
        const horaStr = horaInicio.toLocaleTimeString("pt-BR", {
          hour: "2-digit",
          minute: "2-digit",
          timeZone: "America/Sao_Paulo",
        });

        // Send notification to the assigned barber
        for (const barbeiroDoc of barbeirosSnap.docs) {
          const barbeiroData = barbeiroDoc.data();
          if (barbeiroData.id === ag.barbeiro_id || barbeiroDoc.id === String(ag.barbeiro_id)) {
            await sendNotificationToUser(
              barbeariaId,
              barbeiroDoc.id,
              "Lembrete de agendamento",
              `${clienteNome} agendado para ${horaStr}`
            );
            break;
          }
        }

        // Mark as reminded
        await agDoc.ref.update({ lembrete_enviado: true });
      }
    }

    console.log("Agendamento reminders processed successfully");
    return null;
  });

// ---------------------------------------------------------------------------
// 3. On Agendamento Created (Firestore trigger)
// ---------------------------------------------------------------------------

exports.onAgendamentoCreated = functions.firestore
  .document("barbearias/{barbeariaId}/agendamentos/{agendamentoId}")
  .onCreate(async (snap, context) => {
    const { barbeariaId } = context.params;
    const agendamento = snap.data();

    // Look up client name
    let clienteNome = "Novo cliente";
    if (agendamento.cliente_id) {
      const clientesSnap = await db
        .collection("barbearias")
        .doc(barbeariaId)
        .collection("clientes")
        .where("id", "==", agendamento.cliente_id)
        .limit(1)
        .get();

      if (!clientesSnap.empty) {
        clienteNome = clientesSnap.docs[0].data().nome || "Novo cliente";
      }
    }

    const horaInicio = new Date(agendamento.data_hora_inicio);
    const horaStr = horaInicio.toLocaleTimeString("pt-BR", {
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "America/Sao_Paulo",
    });
    const dataStr = horaInicio.toLocaleDateString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      timeZone: "America/Sao_Paulo",
    });

    // Find the barber by barbeiro_id and send notification
    const barbeirosSnap = await db
      .collection("barbearias")
      .doc(barbeariaId)
      .collection("usuarios")
      .where("role", "==", "barbeiro")
      .where("ativo", "==", true)
      .get();

    for (const barbeiroDoc of barbeirosSnap.docs) {
      const barbeiroData = barbeiroDoc.data();
      if (barbeiroData.id === agendamento.barbeiro_id || barbeiroDoc.id === String(agendamento.barbeiro_id)) {
        await sendNotificationToUser(
          barbeariaId,
          barbeiroDoc.id,
          "Novo agendamento",
          `${clienteNome} - ${dataStr} as ${horaStr}`
        );
        break;
      }
    }

    console.log(
      `Notification sent for new agendamento ${context.params.agendamentoId} in barbearia ${barbeariaId}`
    );

    // TODO: Send WhatsApp notification via API integration
  });

// ---------------------------------------------------------------------------
// 4. On Assinatura Expiring (Scheduled - daily at 09:00)
// ---------------------------------------------------------------------------

exports.onAssinaturaExpiring = functions.pubsub
  .schedule("every day 09:00")
  .timeZone("America/Sao_Paulo")
  .onRun(async (_context) => {
    const now = new Date();
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const barbearias = await db.collection("barbearias").get();

    for (const barbearia of barbearias.docs) {
      const barbeariaId = barbearia.id;

      // Find active subscriptions expiring in the next 7 days
      const assinaturasSnap = await db
        .collection("barbearias")
        .doc(barbeariaId)
        .collection("assinaturas")
        .where("status", "==", "ativo")
        .where("data_vencimento", "<=", sevenDaysFromNow.toISOString())
        .where("data_vencimento", ">=", now.toISOString())
        .get();

      if (assinaturasSnap.empty) continue;

      const count = assinaturasSnap.size;
      const plural = count === 1 ? "assinatura vence" : "assinaturas vencem";

      await notifyAdmins(
        barbeariaId,
        "Assinaturas expirando",
        `${count} ${plural} nos proximos 7 dias. Verifique no app.`
      );

      console.log(
        `Notified admins of barbearia ${barbeariaId}: ${count} expiring subscriptions`
      );
    }

    console.log("Assinatura expiration check completed");
    return null;
  });
