Shader "URP/ShaderBook/Chapter 11/Water"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _BaseMap("BaseMap",2D) = "white"{}
        _Magnitude("Distortion Magnitude",float) = 1    //振幅
        _Frequency("Distortion Frequency",float) = 1    //频率
        _InvWaveLength("Distortion Inverse Wave Length",float) = 10 //波长倒数
        _Speed("Speed",float) = 0.5        
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _Magnitude;
                float  _Frequency;
                float  _InvWaveLength;
                float  _Speed;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;

                float4 offset;
                offset.yzw = float3(0,0,0);  //只希望在X轴进行移动，因此将yzw的位置偏移量都设置为0

                //利用_Frequency属性(频率)和内置的_Time(时间)来控制正弦函数
                offset.x = sin(_Frequency * _Time.y + v.positionOS.x * _InvWaveLength + v.positionOS.y * _InvWaveLength + v.positionOS.z * _InvWaveLength) * _Magnitude;
                //通过原点的顶点上添加一个位置参数来操作顶点运动
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz + offset);
                
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.uv +=float2(0.0,_Time.y * _Speed);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);

                FinalColor = half4(baseMap.rgb * _Color.rgb , _Color.a);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
