using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

//Bloom是建立在高斯模糊基础上，因此需要加入高斯模糊的部分
[Serializable,VolumeComponentMenu("CustomPostProcessing/Bloom")]
public class BloomVolume : VolumeComponent
{
    public ClampedIntParameter interations = new ClampedIntParameter(3 , 0 , 4);                                 //迭代次数
    public ClampedFloatParameter bulrSize = new ClampedFloatParameter(0.6f , 0.2f , 3.0f);                     //对应shader里面定义的_BlurSize属性 ， 模糊范围
    public ClampedIntParameter downSample = new ClampedIntParameter(2 , 1 , 8);                                 //缩放系数
    public ClampedFloatParameter LuminanceThreshold = new ClampedFloatParameter(0.6f , 0.0f , 4.0f);            //明度阈值

}
