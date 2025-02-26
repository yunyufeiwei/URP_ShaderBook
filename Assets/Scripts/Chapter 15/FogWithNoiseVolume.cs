using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable,VolumeComponentMenu("CustomPostProcessing/FogWithNoise")]
public class FogWithNoiseVolume : VolumeComponent
{
    public ClampedFloatParameter FogDensity = new ClampedFloatParameter(1.0f , 0.0f , 3.0f);
    public ColorParameter FogColor = new ColorParameter(Color.black , true);
    public FloatParameter FogStart = new FloatParameter(0.0f , true);
    public FloatParameter FogEnd = new FloatParameter(2.0f , true);
    public ClampedFloatParameter FogXSpeed = new ClampedFloatParameter(0.1f , -0.5f , 0.5f);
    public ClampedFloatParameter FogYSpeed = new ClampedFloatParameter(0.1f , -0.5f , 0.5f);
    public ClampedFloatParameter NoiseAmount = new ClampedFloatParameter(1.0f , 0.0f , 3.0f);
    public Texture2DParameter NoiseTex = new Texture2DParameter(null);
}
