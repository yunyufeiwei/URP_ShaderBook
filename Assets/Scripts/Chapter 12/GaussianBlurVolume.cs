using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[Serializable,VolumeComponentMenu("CustomPostProcessing/GaussianBlur")]
public class GaussianBlurVolume : VolumeComponent
{
    public ClampedIntParameter interations = new ClampedIntParameter(0, 0, 4);  //迭代次数
    public ClampedFloatParameter blurSize = new ClampedFloatParameter(0.0f, 0.0f, 3.0f);    //对应Shader里面定义的_BlurSize属性，模糊范围
    public ClampedIntParameter downSample = new ClampedIntParameter(1, 1, 8);   //模糊的降采样次数
}
