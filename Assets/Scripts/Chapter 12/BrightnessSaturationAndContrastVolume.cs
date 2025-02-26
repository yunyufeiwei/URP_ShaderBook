using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/BrightnessSaturationAndContrast")]
public class BrightnessSaturationAndContrastVolume : VolumeComponent
{
    public ClampedFloatParameter brightness = new ClampedFloatParameter(1.0f , 0.1f , 3.0f);
    public ClampedFloatParameter saturation = new ClampedFloatParameter(1.0f , 0.0f , 6.0f);
    public ClampedFloatParameter contrast   = new ClampedFloatParameter(1.0f , 0.1f , 6.0f);
}
