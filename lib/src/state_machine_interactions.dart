/// InteractionType bit flags returned by `dotlottie_state_machine_get_framework_setup`,
/// declaring which pointer interactions the loaded state machine needs.
///
/// Mirrors `InteractionType: u16` in dotlottie-rs (`src/c_api/types.rs`). Kept in a
/// pure-Dart file (no `dart:ffi`) so the widget layer can consult them on every
/// platform, including web.
library;

const int kInteractionPointerUp = 1 << 0;
const int kInteractionPointerDown = 1 << 1;
const int kInteractionPointerEnter = 1 << 2;
const int kInteractionPointerExit = 1 << 3;
const int kInteractionPointerMove = 1 << 4;
const int kInteractionClick = 1 << 5;
const int kInteractionOnComplete = 1 << 6;
const int kInteractionOnLoopComplete = 1 << 7;
