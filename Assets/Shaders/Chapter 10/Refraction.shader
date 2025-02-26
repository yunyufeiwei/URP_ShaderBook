Shader "URP/Chapter 10/Refraction"
{
    Properties
    {
        _Color("Color" , Color) = (1,1,1,1)
        _RefractColor("Refraction Color" , Color) = (1,1,1,1)
        _RefractAmount("Refraction Amount" , Range(0 , 1)) = 1
        _RefractRatio("Refract Ratio" , Range(0.1 , 1)) = 0.5
        _Cubemap("Cubemap" , Cube) = "_Skybox"{}    
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            
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
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewDirWS    : TEXCOORD2;
                float3 worldRefr    : TEXCOORD3;
            };

            TEXTURECUBE(_Cubemap);SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                half4 _RefractColor;
                half  _RefractAmount;
                half  _RefractRatio;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);

                //使用CG函数refract函数来计算折射方向，第一个参数为入射光线的方向（它必须是归一化的），第二个参数是表面法线（它必须是归一化的），第三个参数是入射光线所在介质和这是光线所在介质的折射率之间的比值
                o.worldRefr = refract(-normalize(o.viewDirWS) , normalize(o.normalWS) , _RefractRatio);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 worldLightDir = light.direction;

                half3 worldNormal = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewDirWS);

                half3 diffuse = lightColor * _Color * max(0 , dot(worldNormal , worldLightDir));

                half3 refraction = SAMPLE_TEXTURECUBE(_Cubemap , sampler_Cubemap , i.worldRefr).rgb * _RefractColor.rgb;

                FinalColor = half4(lerp(diffuse , refraction , _RefractAmount) , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
