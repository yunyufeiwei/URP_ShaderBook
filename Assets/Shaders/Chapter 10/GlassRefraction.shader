Shader "URP/Chapter 10/GlassRefraction"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        _BumpMap("NormalMap" , 2D) = "bump"{}
        _Cubemap("Cubemap" , Cube) = "_Skybox"{}
        _Distortion("Distortion" , Range(0 ,100)) = 10          //控制模拟这是时图像的扭曲程度
        _RefractAmount("Refract Amount" , Range(0 ,1)) = 1      //控制折射程度，当为0时，该玻璃只包含反射，当为1时，该玻璃只包含折射
    }
    SubShader
    {
        //将渲染队列设置为透明，这样其他的不透明物体都会在这个之前被渲染到屏幕上
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Transparent"}
        
        //GrabPass{ "_RefractionTex"}

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define REQUIRE_OPAQUE_TEXTURE
           
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : POSITION;
                float4 scrPosition  : TEXCOORD0;
                float4 uv           : TEXCOORD1;
                float4 TtoW0        : TEXCOORD2;
                float4 TtoW1        : TEXCOORD3;
                float4 TtoW2        : TEXCOORD4;
                float3 viewDirWS    : TEXCOORD5;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);
            TEXTURECUBE(_Cubemap);SAMPLER(sampler_Cubemap);
            TEXTURE2D (_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BumpMap_ST;
                float  _Distortion;
                float  _RefractAmount;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.uv.xy = TRANSFORM_TEX(v.texcoord , _BaseMap);
                o.uv.zw = TRANSFORM_TEX(v.texcoord , _BumpMap);

                float3 positionWS = mul(unity_ObjectToWorld , v.positionOS).xyz;
                float3 worldNormal = TransformObjectToWorldNormal(v.normalOS);
                float3 worldTangent = TransformObjectToWorldDir(v.tangentOS.xyz);
                half signDir = real(v.tangentOS.w) * GetOddNegativeScale();
                float3 worldBinormal = cross(worldNormal , worldTangent) * signDir;

                o.viewDirWS = GetWorldSpaceViewDir(positionWS);

                //将计算结果按列摆放得到从切线空间到世界空间的变换矩阵，将该矩阵的每一行分别存储在TtoW0、TtoW1、TtoW2中，并将世界空间下的顶点位置分别存储在了变量的W分量中
                o.TtoW0 = float4(worldTangent.x , worldBinormal.x , worldNormal.x , positionWS.x);
                o.TtoW1 = float4(worldTangent.y , worldBinormal.y , worldNormal.y , positionWS.y);
                o.TtoW2 = float4(worldTangent.z , worldBinormal.z , worldNormal.z , positionWS.z);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FianlColor;
                float2 screenUV = i.positionHCS.xy / _ScreenParams.xy;

                half3 worldViewDir = normalize(i.viewDirWS);

                //得到切线空间下的法线信息,采样并进行解码
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap , sampler_BumpMap , i.uv);
                half3 normalTS = UnpackNormal(normalMap);
                half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz , normalTS) , dot(i.TtoW1.xyz , normalTS) , dot(i.TtoW2.xyz , normalTS)));

                half3 reflDir = reflect(-worldViewDir , worldNormal);

                //计算切线空间的偏移量
                float2 offset = normalTS.xy * _Distortion;
                screenUV.xy = offset + screenUV.xy;
                half4 screenColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV);
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv.xy);
                half3 reflCol = SAMPLE_TEXTURECUBE(_Cubemap , sampler_Cubemap ,  reflDir).rgb * baseMap.rgb;

                half4 finalColor = half4(reflCol * (1 - _RefractAmount) + screenColor * _RefractAmount , 1.0);
                
                return finalColor;                          
            }
            ENDHLSL
        }
    }
}
