.PHONY: test analyze deploy-rules deploy-indexes deploy-all clean

test:
	flutter test

analyze:
	flutter analyze

deploy-rules:
	firebase deploy --only firestore:rules

deploy-indexes:
	firebase deploy --only firestore:indexes

deploy-all:
	firebase deploy --only firestore

clean:
	flutter clean
	flutter pub get
