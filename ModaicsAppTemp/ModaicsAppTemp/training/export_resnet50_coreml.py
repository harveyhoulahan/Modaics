# export_resnet50_coreml.py

import os
import certifi
import torch
import torchvision.models as models
import coremltools as ct

# Ensure urllib uses certifi’s certificate bundle
os.environ["SSL_CERT_FILE"] = certifi.where()

# 1) Load pretrained ResNet50, strip classifier
resnet = models.resnet50(pretrained=True)
resnet.fc = torch.nn.Identity()
resnet.eval()

# 2) Trace with a dummy 1×3×224×224 input
example_input = torch.rand(1, 3, 224, 224)
traced_model = torch.jit.trace(resnet, example_input)

# 3) Convert to a flat NeuralNetwork .mlmodel
nnmodel = ct.convert(
    traced_model,
    source="pytorch",
    inputs=[ct.ImageType(
        name="input_image",
        shape=example_input.shape,
        scale=1/255.0,
        bias=[0.485, 0.456, 0.406]
    )],
    convert_to="neuralnetwork",                 # ← force “NeuralNetwork”
    minimum_deployment_target=ct.target.iOS14    # or iOS13 if needed
)

nnmodel.short_description = "ResNet50 (NN) feature extractor"
nnmodel.input_description["input_image"] = "224×224 image, normalized to ImageNet"

# (Optional) If you want to set the output description, discover its true name:
#   actual_output = nnmodel.get_spec().description.output[0].name
#   nnmodel.output_description[actual_output] = "2048-d embedding"

os.makedirs("models", exist_ok=True)
nnmodel.save("models/ResNet50Embedding.mlmodel")
print("✅ Saved flat NeuralNetwork model to models/ResNet50Embedding.mlmodel")
