Shader "URP/Chapte 11/ShadowCasterPass"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        _Color("Color Tint",Color)=(1,1,1,1)
        _Magnitude("Distortion Magnitude",float)=1
        _Frequency("Distortion Frequency",float)=1
        _InvWaveLength("Distortion Inverse Wave Length",float)=10
        _Speed("Speed",float)=0.5
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "Queue"="Transparent"  "RenderType"="Transparent"}
        LOD 100

        pass
        {
            Tags{"LightMode" = "UniversalForward"}      
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 texcoord : TEXCOORD;
            };
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv:TEXCOORD;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _Color;
                float _Magnitude;
                float _Frequency;
                float _InvWaveLength;
                float _Speed;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                float4 offset;
                offset.yzw=float3(0,0,0);  //只希望在x轴进行移动，因此将y z w的位移量设置为0
                offset.x=sin(_Frequency * _Time.y + v.positionOS.x * _InvWaveLength + v.positionOS.y * _InvWaveLength + v.positionOS.z * _InvWaveLength)*_Magnitude;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz + offset.xyz);

                o.uv=TRANSFORM_TEX(v.texcoord , _BaseMap);
                o.uv += float2 (0,_Time.y * _Speed);  //进行纹理动画

                return o;
            }

            half4 frag(Varyings i):SV_TARGET
            {
                half4 FinalColor;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);

                half3 diffuse = baseMap.rgb * _Color.rgb; 

                FinalColor = half4(diffuse , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }

        //自定义阴影部分
        //URP下的阴影需要添加额外的Pass，将其阴影的lightMode设置为{"LightMode" = "ShadowCaster"
        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };
            struct Varyings
            {
                float4 positionCS  : SV_POSITION;       //裁剪空间的维度是四维的
            };

            CBUFFER_START(UnityPerMaterial)
                float _Magnitude;
                float _Frequency;
                float _InvWaveLength;
                float _Speed;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings) 0;

                float4 offset;
				offset.yzw = float3(0.0, 0.0, 0.0);
				offset.x = sin(_Frequency * _Time.y + v.positionOS.x * _InvWaveLength + v.positionOS.y * _InvWaveLength + v.positionOS.z * _InvWaveLength) * _Magnitude;
				v.positionOS = v.positionOS + offset;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

                //\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\Editor\ShaderGraph\Includes\Varyings.hlsl
                //获取阴影专用裁剪空间下的坐标
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, float3(0,0,0)));
                //判断是否在DirectX平台翻转过坐标
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                    o.positionCS = positionCS;

                return o;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
