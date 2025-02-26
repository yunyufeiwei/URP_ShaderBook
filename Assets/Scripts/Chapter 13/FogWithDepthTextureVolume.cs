using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/FogWithDepthTexture")]
public class FogWithDepthTextureVolume : VolumeComponent
{
    public ClampedFloatParameter FogDensity = new ClampedFloatParameter(1.0f , 0.0f , 3.0f);
    public ColorParameter FogColor = new ColorParameter(Color.black , true);
    public FloatParameter FogStart = new FloatParameter(0.0f , true);
    public FloatParameter FogEnd = new FloatParameter(2.0f , true);
}
