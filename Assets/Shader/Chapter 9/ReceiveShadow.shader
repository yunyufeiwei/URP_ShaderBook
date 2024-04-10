Shader "URP/ShaderBook/Chapter 9/ReceiveShadow"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _BaseMap("BaseMap",2D) = "white"{}
        _SpecularColor("SpecularColor",Color) = (1,1,1,1)
        [PowerSlider(20)]_SpecularPower("SpecularPower",Range(8,255)) = 20
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
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
                float3 viewDirWS    : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float4 _SpecularColor;
                float  _SpecularPower;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                o.uv = TRANSFORM_TEX(v.texcoord,_BaseMap);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                //获取光照的时候同时获取阴影
                Light light = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 worldLightDir = light.direction;
                half4 lightColor = half4(light.color * light.distanceAttenuation * light.shadowAttenuation , 1.0);

                half3 worldNormal = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewDirWS);
                half3 halfDir = normalize(worldLightDir+worldViewDir);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);

                half3 diffuse = lightColor.rgb * _Color.rgb * baseMap.rgb * max(0.0,dot(worldNormal,worldLightDir));
                half3 specular = lightColor.rgb * _SpecularColor * pow(max(0.0,dot(worldNormal,halfDir)),_SpecularPower);

                //支持额外光源
                int additionalLightCount = GetAdditionalLightsCount();  //获取额外光源数量
                for(int j = 0;j<additionalLightCount;j++)
                {
                    light = GetAdditionalLight(j,i.positionWS);
                    half3 attenuatedLightColor = light.color * light.distanceAttenuation;
                    diffuse += LightingLambert(light.color,light.direction,worldNormal);
                    specular += LightingSpecular(light.color,light.direction,worldNormal,worldViewDir,_SpecularColor,_SpecularPower);
                }
                
                FinalColor = half4(diffuse + specular,1.0);
                
                return FinalColor;
            }
            ENDHLSL
        }

        //URP下的阴影需要额外添加阴影的pass（使用Lit.shader的pass直接生成）
//        Pass
//        {
//            Name "ShadowCaster"
//            Tags
//            {
//                "LightMode" = "ShadowCaster"
//            }
//
//            // -------------------------------------
//            // Render State Commands
//            ZWrite On
//            ZTest LEqual
//            ColorMask 0
//            Cull[_Cull]
//
//            HLSLPROGRAM
//            #pragma target 2.0
//
//            // -------------------------------------
//            // Shader Stages
//            #pragma vertex ShadowPassVertex
//            #pragma fragment ShadowPassFragment
//
//            // -------------------------------------
//            // Material Keywords
//            #pragma shader_feature_local_fragment _ALPHATEST_ON
//            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//
//            //--------------------------------------
//            // GPU Instancing
//            #pragma multi_compile_instancing
//            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
//
//            // -------------------------------------
//            // Universal Pipeline keywords
//
//            // -------------------------------------
//            // Unity defined keywords
//            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
//
//            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
//            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
//
//            // -------------------------------------
//            // Includes
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
//            ENDHLSL
//        }
        
        //方案二：
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
