# file: extract_embeddings.py

import os
import torch
import torchvision.transforms as transforms
from torchvision import models
from PIL import Image
import numpy as np
import joblib

# 1) Load a pretrained ResNet50 (without final classification layer)
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
resnet = models.resnet50(pretrained=True)
# Remove the final fully connected layer
resnet.fc = torch.nn.Identity()
resnet = resnet.to(device)
resnet.eval()

# 2) Preprocessing pipeline
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

def embed_image(image_path: str) -> np.ndarray:
    img = Image.open(image_path).convert("RGB")
    x = preprocess(img).unsqueeze(0).to(device)  # shape [1,3,224,224]
    with torch.no_grad():
        embedding = resnet(x)  # shape [1, 2048]
    return embedding.cpu().numpy().squeeze()  # shape [2048,]

# 3) Loop through images and collect embeddings
image_folder = "data/train_images"
filenames = sorted(os.listdir(image_folder))
embeddings = []    # list of np.ndarray shape (2048,)
paths = []

for fname in filenames:
    if not fname.lower().endswith((".jpg", ".png", ".jpeg")):
        continue
    full_path = os.path.join(image_folder, fname)
    vec = embed_image(full_path)
    embeddings.append(vec)
    paths.append(fname)

embeddings = np.stack(embeddings)  # shape [N, 2048]

# 4) Build a nearest neighbor index
from sklearn.neighbors import NearestNeighbors

# Fit a brute-force cosine sim index (for MVP; for large N, consider Faiss)
nn = NearestNeighbors(n_neighbors=6, metric="cosine")  # top 6: first neighbor will be itself
nn.fit(embeddings)  # `embeddings` should be a float32 array

# 5) Save embeddings and index to disk
os.makedirs("models", exist_ok=True)
joblib.dump({
    "paths": paths,           # list of filenames
    "embeddings": embeddings, # ndarray [N, 2048]
}, "models/embeddings.pkl")
joblib.dump(nn, "models/nn_index.pkl")

print("Saved embeddings and nearest-neighbor index.")
