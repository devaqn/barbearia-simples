# BarberOS — Gestão profissional para barbearias

Produto de software genérico. Cada cliente (barbearia) recebe:
- Um **Firebase project** próprio
- Uma **chave de licença** de 24 caracteres gerada pelo desenvolvedor

---

## Pré-requisitos

- Flutter 3.x (stable)
- Firebase CLI: `npm install -g firebase-tools`
- Conta no Firebase Console

---

## 1. Criar projeto Firebase para um novo cliente

1. Acesse o Firebase Console e crie um novo projeto
2. Ative **Authentication** → método Email/Senha
3. Ative **Cloud Firestore** (modo produção)
4. Ative **App Check** (Play Integrity para Android)
5. Ative **Crashlytics**
6. Adicione um app Android com package `com.barberos.app`
7. Copie as credenciais (api_key, app_id, sender_id, project_id)

---

## 2. Deploy das regras Firestore

```bash
firebase login
firebase use <PROJECT_ID>
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 3. Gerar chave de licença

```python
import hashlib
key  = "AAAAAAAABBBBBBBBCCCCCCCC"  # 24 chars — defina sua chave
salt = "barberos_salt_v1"
h = hashlib.sha256((key + salt).encode()).hexdigest()
print(h)  # passe como --dart-define=LICENSE_HASH=<h>
```

---

## 4. Build de release Android

```bash
flutter build apk --release \
  --dart-define=FIREBASE_API_KEY=<api_key> \
  --dart-define=FIREBASE_APP_ID=<app_id> \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=<sender_id> \
  --dart-define=FIREBASE_PROJECT_ID=<project_id> \
  --dart-define=FIREBASE_STORAGE_BUCKET=<project>.appspot.com \
  --dart-define=LICENSE_HASH=<hash> \
  --dart-define=LICENSE_SALT=barberos_salt_v1 \
  --dart-define=MP_PUBLIC_KEY=<mp_key> \
  --dart-define=MP_ACCESS_TOKEN=<mp_token>
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Primeiro acesso no dispositivo

1. Instale o APK
2. App abre na **Tela de Ativação de Licença** — insira a chave de 24 chars
3. Após ativação, app vai para login
4. Crie o admin na tela de setup inicial

---

## 6. Substituir logo

Substitua `assets/images/logo.png` por PNG 512×512px antes do build.

---

## Variáveis --dart-define

| Variável | Obrigatório | Descrição |
|---|---|---|
| FIREBASE_API_KEY | Sim | API key do Firebase |
| FIREBASE_APP_ID | Sim | App ID Android |
| FIREBASE_MESSAGING_SENDER_ID | Sim | Sender ID |
| FIREBASE_PROJECT_ID | Sim | Project ID |
| LICENSE_HASH | Sim | SHA-256(chave+salt) |
| LICENSE_SALT | Não | Salt (padrão: barberos_salt_v1) |
| MP_PUBLIC_KEY | Não | Mercado Pago public key |
| MP_ACCESS_TOKEN | Não | Mercado Pago access token |
| PRIMARY_COLOR | Não | Cor ARGB hex (ex: FF4A4AFF) |
