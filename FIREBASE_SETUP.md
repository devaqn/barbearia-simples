# BarberOS — Firebase Setup Guide

## 1. Criar Projeto Firebase

1. Acesse [console.firebase.google.com](https://console.firebase.google.com)
2. "Adicionar projeto" → Defina um nome (ex: `barberos-cliente-x`)
3. Desative o Google Analytics (opcional para simplicidade)

## 2. Authentication

- Console → Authentication → Começar
- Ativar provedor: **Email/senha**

## 3. Cloud Firestore

- Console → Firestore Database → Criar banco de dados
- Selecione **modo produção**
- Escolha a região mais próxima

### Deploy das Regras

```bash
npm install -g firebase-tools
firebase login
firebase use <PROJECT_ID>
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

## 4. App Check

- Console → App Check → Começar
- Para Android: selecione **Play Integrity** (produção) ou **Debug** (desenvolvimento)
- Registre o app Android

## 5. Crashlytics

- Console → Crashlytics → Começar
- Siga o wizard para o app Android

## 6. Adicionar App Android

- Console → Configurações do projeto → Adicionar app → Android
- Package: `com.barberos.app`
- Baixe `google-services.json`
- Coloque em `android/app/google-services.json`

## 7. Coletar credenciais

No `google-services.json`, localize:
- `api_key[0].current_key` → `FIREBASE_API_KEY`
- `client[0].client_info.mobilesdk_app_id` → `FIREBASE_APP_ID`
- `project_info.project_number` → `FIREBASE_MESSAGING_SENDER_ID`
- `project_info.project_id` → `FIREBASE_PROJECT_ID`
- `project_info.storage_bucket` → `FIREBASE_STORAGE_BUCKET`

## 8. Build com as credenciais

```bash
flutter build apk --release \
  --dart-define=FIREBASE_API_KEY=AIzaSy... \
  --dart-define=FIREBASE_APP_ID=1:123456:android:abc \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=123456789 \
  --dart-define=FIREBASE_PROJECT_ID=barberos-cliente-x \
  --dart-define=FIREBASE_STORAGE_BUCKET=barberos-cliente-x.appspot.com \
  --dart-define=LICENSE_HASH=<hash_sha256> \
  --dart-define=LICENSE_SALT=barberos_salt_v1
```

## 9. Estrutura Firestore

Todas as coleções ficam em:
```
/barbearias/{barbeariaId}/{collection}/{docId}
```

O `barbeariaId` é gerado automaticamente no primeiro boot e salvo no Secure Storage do dispositivo.

## Regras de Segurança

O arquivo `firestore.rules` implementa:
- `isInShop()` — usuário autenticado + não revogado + ativo
- `isAdmin()` — role == 'admin'
- `isBootstrapAdmin()` — permite criar o primeiro admin
- Barbeiros não podem modificar campos financeiros de clientes
- Barbeiros não podem alterar preços ou estoque mínimo de produtos
- Despesas e caixas: somente admin
- Comandas: barbeiro vê apenas as suas
