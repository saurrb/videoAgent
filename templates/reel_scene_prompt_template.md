# Scene Prompt Template (Meta AI)

Use one prompt per scene. Keep the same `character_anchor` text in every scene for continuity.

## Global Character Anchor

`A realistic adult woman named Flora, natural skin texture, consistent facial identity, cinematic soft lighting, photoreal style, no cartoon look.`

## Scene Prompt

```text
Create a vertical 9:16 cinematic video scene, duration {DURATION_SECONDS}s.

Character anchor:
{CHARACTER_ANCHOR}

Scene intent:
{SCENE_INTENT}

Action:
{ACTION_BLOCK}

Camera:
{CAMERA_BLOCK}

Mood:
{MOOD_BLOCK}

Hard constraints:
- keep same face identity as previous scenes
- realistic motion, no distortion
- no text overlays
- no logos/watermarks
```

## Example (Scene 1 Hook)

```text
Create a vertical 9:16 cinematic video scene, duration 5s.

Character anchor:
A realistic adult woman named Flora, natural skin texture, consistent facial identity, cinematic soft lighting, photoreal style, no cartoon look.

Scene intent:
Hook line setup with direct eye contact.

Action:
Flora looks into camera, subtle inhale, small reflective smile.

Camera:
Slow push-in from medium close-up to close-up.

Mood:
Quiet, intimate, emotional.

Hard constraints:
- keep same face identity as previous scenes
- realistic motion, no distortion
- no text overlays
- no logos/watermarks
```
