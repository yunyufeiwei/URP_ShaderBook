Shader "URP/Chapte 11/Water"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        _Color("Color Tint",Color)=(1,1,1,1)
        _Magnitude("Distortion Magnitude",float)=1  //波动幅度（高低的大小）
        _Frequency("Distortion Frequency",float)=1  //波动频率（速度）
        _InvWaveLength("Distortion Inverse Wave Length",float)=10   //波长的倒数
        _Speed("Speed",float)=0.5
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry"} 

        pass
        {
            Tags{"LightMode" = "UniversalForward"}

            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes 
			{
				float4 positionOS 	: POSITION;
				float4 texcoord 	: TEXCOORD0;
			};

           struct Varyings 
		    {
				float4 positionHCS 	: SV_POSITION;
				float2 uv 			: TEXCOORD0;
			};

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _Color;
                float  _Magnitude;
                float  _Frequency;
                float  _InvWaveLength;
                float  _Speed;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                float4 offset;
                offset.yzw = float3(0,0,0);  //只希望在x轴进行移动，因此将y z w的位移量设置为0

                //利用_Frequency属性和内置的_Time.y用来控制正弦函数的频率
                offset.x = sin(_Frequency * _Time.y + v.positionOS.x * _InvWaveLength + v.positionOS.y * _InvWaveLength + v.positionOS.z * _InvWaveLength)*_Magnitude;
                //通过在原有顶点上添加一个位移参数来操作顶点移动
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz + offset);

                o.uv = TRANSFORM_TEX(v.texcoord , _BaseMap);
                o.uv += float2 (0 , _Time.y * _Speed);  //进行纹理动画

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);

                FinalColor = half4(baseMap.rgb * _Color.rgb , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
