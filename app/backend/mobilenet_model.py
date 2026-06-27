import tensorflow as tf
import numpy as np
import json
from keras.utils import load_img, img_to_array

# Load trained model
model = tf.keras.models.load_model("model/foodlens_model.keras")

# Load class names
with open("model/class_names.json", "r") as f:
    class_indices = json.load(f)

# Ensure correct order
class_names = [k for k, v in sorted(class_indices.items(), key=lambda x: x[1])]

def detect_food(image_path):

    # Load image
    img = load_img(image_path, target_size=(224, 224))

    # Convert image to array
    img_array = img_to_array(img)

    # Normalize
    img_array = img_array / 255.0

    # Add batch dimension
    img_array = np.expand_dims(img_array, axis=0)

    # Predict
    prediction = model.predict(img_array, verbose=0)

    # Get highest confidence class
    predicted_index = np.argmax(prediction)

    # Return food name
    return [class_names[predicted_index]]