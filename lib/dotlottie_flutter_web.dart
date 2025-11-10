// Export the correct implementation based on platform
export 'dotlottie_flutter_web_stub.dart'
    if (dart.library.js_interop) 'dotlottie_flutter_web_impl.dart';
