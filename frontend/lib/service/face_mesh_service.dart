import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

class FaceMeshService {
  late FaceMeshDetector _detector;

  FaceMeshService() {
    _detector = FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
  }

  Future<List<FaceMesh>> detectMesh(InputImage inputImage) async {
    return await _detector.processImage(inputImage);
  }

  void dispose() {
    _detector.close();
  }
}
