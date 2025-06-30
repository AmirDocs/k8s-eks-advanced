# realtime_object_detection.py

import cv2
from ultralytics import YOLO

def main():
    # Path to your YOLOv8 model (replace with your model path)
    model_path = 'yolov8n.pt'  

    # Initialize the YOLOv8 model
    model = YOLO(model_path)

    # Initialize webcam (0 is usually the default camera)
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return

    # Set webcam resolution (optional)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

    print("Starting real-time object detection. Press 'q' to exit.")

    while True:
        # Read a frame from the webcam
        ret, frame = cap.read()
        if not ret:
            print("Failed to grab frame.")
            break

        # Perform object detection
        results = model(frame)

        # Annotate the frame with detections
        annotated_frame = results[0].plot()  # plot() returns a BGR image

        # Display the resulting frame
        cv2.imshow('YOLOv8 Real-Time Object Detection', annotated_frame)

        # Exit condition: press 'q' to quit
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    # Release resources
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()