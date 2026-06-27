from ultralytics import YOLO

model = YOLO("runs/detect/train-4/weights/best.pt")

def detect_food(image_path):
    results = model(image_path)
    
    foods = []
    for r in results:
        for box in r.boxes:
            foods.append(model.names[int(box.cls)])
    
    return foods