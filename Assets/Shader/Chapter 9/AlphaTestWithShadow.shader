Shader "URP/ShaderBook/Chapter 9/AlphaTestWithShadow"
{
    Properties
    {
        _Color("Color",color) = (1,1,1,1)
        _BaseMap("BaseMap",2D) = "white"{}
        _Cutoff("Alpha Cutoff",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="TransparentCutout" "Queue" = "AlphaTest"}
        LOD 100

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //接收阴影的宏定义
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT    
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _Cutoff;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                o.uv = TRANSFORM_TEX(v.texcoord,_BaseMap);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 worldLightDir = light.direction;
                half4 lightColor = half4(light.color * light.distanceAttenuation * light.shadowAttenuation , 1.0);

                half3 worldNormal = normalize(i.normalWS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);

                half4 diffuse = lightColor * _Color * baseMap * max(0.0,dot(worldLightDir,worldNormal) * 0.5 + 0.5);

                //Alpha测试
                clip(baseMap.a - _Cutoff);

                FinalColor = diffuse;
                
                return FinalColor;
            }
            ENDHLSL
        }
    
        //阴影
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
            };

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(v.normalOS);

                //获取阴影专用裁剪空间下的坐标
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS,normalWS,float3(0,0,0)));
                //判断是否在DirectX平台反转坐标
                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z,positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z,positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif        
                o.positionHCS = positionCS;

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                return 0;
            }
            ENDHLSL
        }
    }
}