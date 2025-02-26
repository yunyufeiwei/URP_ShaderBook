using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/EdgeDetectionVolume")]
public class EdgeDetectionVolume : VolumeComponent
{
    public ClampedFloatParameter edgeOnly = new ClampedFloatParameter(0 , 0 , 1);
    public ColorParameter edgeColor = new ColorParameter(Color.black , true);
    public ColorParameter backGroundColor = new ColorParameter(Color.white , true);
}
