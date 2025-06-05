.PHONY: help setup train test deploy-ios deploy-backend clean

help:
	@grep -E '^[a-zA-Z_-]+:' Makefile | cut -d':' -f1 | sort

setup:
	pip install -r backend/requirements.txt
	pip install -r backend/requirements-dev.txt
	cd IOS && swift package resolve

train:
	python backend/training/modaics_training_pipeline.py \
		--data-dir data \
		--output-dir models \
		--epochs 50 --batch-size 64

test:
	pytest tests/ --cov=backend --cov-report=term
	cd IOS && xcodebuild test \
	    -scheme Modaics \
	    -destination 'platform=iOS Simulator,name=iPhone 14'

deploy-ios:
	cd IOS && xcodebuild archive \
	    -scheme Modaics \
	    -configuration Release \
	    -archivePath build/Modaics.xcarchive

deploy-backend:
	firebase deploy --only functions,firestore,storage

clean:
	rm -rf build/ models/ *.coverage .pytest_cache
	find . -name "*.pyc" -delete
