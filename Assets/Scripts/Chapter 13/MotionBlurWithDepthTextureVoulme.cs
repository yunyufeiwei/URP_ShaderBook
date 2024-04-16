using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/MotionBlurWithDepthTexture")]
public class MotionBlurWithDepthTextureVoulme : VolumeComponent
{
    public ClampedFloatParameter blurSize = new ClampedFloatParameter(0.5f, 0.0f, 0.9f);
}
