using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/MotionBlurWithDepthTexture")]
public class MotionBlurWithDepthTextureVolume : VolumeComponent
{
    public ClampedFloatParameter BlurSize = new ClampedFloatParameter(0.5f , 0.0f , 0.9f);
}
