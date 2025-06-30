from flask import Flask, render_template, jsonify
import json
import os
import subprocess
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Global variable to store the camera subprocess
camera_process = None

# Function to load results from the JSON file
def load_results():
    file_path = os.path.join(os.path.dirname(__file__), './results/consolidated_results.json')
    if os.path.exists(file_path):
        with open(file_path, 'r') as file:
            return json.load(file)
    else:
        return {"error": "Results not available. Please run the model first."}

# Function to clear the results folder (deletes only files, keeps the folder)
def clear_results_folder():
    results_folder = os.path.join(os.path.dirname(__file__), 'results')
    if os.path.exists(results_folder):
        for filename in os.listdir(results_folder):
            file_path = os.path.join(results_folder, filename)
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path)  # Delete the file or symlink
            except Exception as e:
                print(f"Failed to delete {file_path}. Reason: {e}")

# Route for the landing page
@app.route("/")
def index():
    return render_template("index.html")

# API endpoint to trigger the model
@app.route("/api/run-model", methods=["POST"])
def run_model():
    try:
        # Step 1: Clear the results folder
        clear_results_folder()

        # Step 2: Run the model.py script
        subprocess.run(["python", "model.py"], check=True)
        return jsonify({"message": "Model executed successfully."})
    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"Error executing model: {str(e)}"}), 500

@app.route("/camera")
def camera():
    return render_template("camera.html")

@app.route("/metrics")
def metrics_endpoint():
    data = generate_latest()
    return data, 200, {'Content-Type': CONTENT_TYPE_LATEST}


# API endpoint to start the webcam object detection
@app.route("/api/use-camera", methods=["POST"])
def use_camera():
    global camera_process
    if camera_process is None or camera_process.poll() is not None:
        try:
            # Run the webcam object detection script as a separate process
            # Ensure the script path is correct
            script_path = os.path.join(os.getcwd(), "camera.py")
            camera_process = subprocess.Popen(["python", script_path])
            return jsonify({"message": "Camera object detection started."}), 200
        except Exception as e:
            return jsonify({"error": f"Error starting camera detection: {str(e)}"}), 500
    else:
        return jsonify({"error": "Camera is already running."}), 400

# API endpoint to stop the webcam object detection
@app.route("/api/stop-camera", methods=["POST"])
def stop_camera():
    global camera_process
    if camera_process and camera_process.poll() is None:
        try:
            # Terminate the subprocess gracefully
            camera_process.terminate()
            camera_process.wait(timeout=5)  # Wait for the process to terminate
            camera_process = None
            return jsonify({"message": "Camera object detection stopped."}), 200
        except subprocess.TimeoutExpired:
            # If the process does not terminate, kill it forcefully
            camera_process.kill()
            camera_process = None
            return jsonify({"message": "Camera object detection forcefully stopped."}), 200
        except Exception as e:
            return jsonify({"error": f"Error stopping camera detection: {str(e)}"}), 500
    else:
        return jsonify({"error": "Camera is not running."}), 400

if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=3000, use_reloader=False)