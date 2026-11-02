import sys
import os
os.environ['OPENCV_LOG_LEVEL'] = 'OFF'
import json
import base64
import cv2
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
YUNET_PATH = os.path.join(BASE_DIR, 'face_models', 'face_detection_yunet.onnx')
SFACE_PATH = os.path.join(BASE_DIR, 'face_models', 'face_recognition_sface.onnx')

# Initialize models
_detector = None
_fallback_detector = None
_recognizer = None

def get_models():
    global _detector, _recognizer
    if _detector is None:
        _detector = cv2.FaceDetectorYN_create(
            YUNET_PATH,
            '',
            (320, 320),
            0.5, 0.3, 5000
        )
    if _recognizer is None:
        _recognizer = cv2.FaceRecognizerSF_create(
            SFACE_PATH,
            ''
        )
    return _detector, _recognizer

def extract_face_feature_from_bgr(img):
    global _fallback_detector
    detector, recognizer = get_models()
    h, w, _ = img.shape
    detector.setInputSize((w, h))
    _, faces = detector.detect(img)
    if faces is None or len(faces) == 0:
        if _fallback_detector is None:
            _fallback_detector = cv2.FaceDetectorYN_create(
                YUNET_PATH, '', (w, h), 0.3, 0.3, 5000
            )
        else:
            _fallback_detector.setInputSize((w, h))
        _, faces = _fallback_detector.detect(img)

    if faces is None or len(faces) == 0:
        return None

    # Pick the face with largest bounding box (closest to camera / centered)
    best_face = faces[0]
    if len(faces) > 1:
        best_face = max(faces, key=lambda f: f[2] * f[3])

    aligned = recognizer.alignCrop(img, best_face)
    feature = recognizer.feature(aligned)
    return feature.flatten().tolist()

def extract_face_feature_from_path(path):
    img = cv2.imread(path)
    if img is None:
        return None
    return extract_face_feature_from_bgr(img)

def extract_face_feature_from_base64(b64_str):
    if ',' in b64_str:
        b64_str = b64_str.split(',', 1)[1]
    img_data = base64.b64decode(b64_str)
    nparr = np.frombuffer(img_data, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img is None:
        return None
    return extract_face_feature_from_bgr(img)

def cosine_similarity(vec_a, vec_b):
    a = np.array(vec_a, dtype=np.float32)
    b = np.array(vec_b, dtype=np.float32)
    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(np.dot(a, b) / (norm_a * norm_b))

def main():
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'Action required'}))
        sys.exit(1)

    action = sys.argv[1]

    if action == 'extract':
        img_path = sys.argv[2]
        feat = extract_face_feature_from_path(img_path)
        if feat is None:
            print(json.dumps({'success': False, 'error': 'No face detected in image'}))
        else:
            print(json.dumps({'success': True, 'feature': feat}))

    elif action == 'match':
        # JSON payload passed on stdin
        input_data = json.loads(sys.stdin.read())
        query_b64 = input_data.get('queryImage')
        enrolled_list = input_data.get('enrolled', [])

        if not query_b64:
            print(json.dumps({'success': False, 'error': 'No query image provided'}))
            return

        query_feat = extract_face_feature_from_base64(query_b64)
        if query_feat is None:
            print(json.dumps({'success': False, 'error': 'No face detected in camera frame. Please center your face inside the frame.'}))
            return

        best_score = -1.0
        best_match = None
        # Threshold for SFace cosine similarity is 0.363
        MATCH_THRESHOLD = 0.363

        for emp in enrolled_list:
            emp_feat = emp.get('faceEmbeddings')
            if not emp_feat or len(emp_feat) != 128:
                continue
            score = cosine_similarity(query_feat, emp_feat)
            if score > best_score:
                best_score = score
                best_match = emp

        if best_match and best_score >= MATCH_THRESHOLD:
            print(json.dumps({
                'success': True,
                'matched': True,
                'score': round(best_score, 4),
                'employee': {
                    'email': best_match.get('email'),
                    'name': best_match.get('name'),
                    'department': best_match.get('department'),
                    'role': best_match.get('role'),
                }
            }))
        else:
            print(json.dumps({
                'success': True,
                'matched': False,
                'score': round(best_score, 4) if best_match else 0.0,
                'message': 'Face detected but did not match any enrolled company employee.'
            }))

if __name__ == '__main__':
    main()
