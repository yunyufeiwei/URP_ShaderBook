using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/EdgeDetectNormalsAndDepth")]
public class EdgeDetectNormalsAndDepthVolume : VolumeComponent
{
    public BoolParameter useEdgeDetect = new BoolParameter(false, true);
    public BoolParameter useDepthNormal = new BoolParameter(true, true);
    
    public ColorParameter edgeColor = new ColorParameter(Color.black , true);
    public ColorParameter backgroundColor = new ColorParameter(Color.white , true);
    public ClampedFloatParameter edgeOnly = new ClampedFloatParameter(0.0f , 0.0f , 1.0f);
    public FloatParameter sampleDistance = new FloatParameter(1.0f , true);
    public FloatParameter sensitivityDepth = new FloatParameter(1.0f , true);
    
    public bool IsActive() => active;
}
