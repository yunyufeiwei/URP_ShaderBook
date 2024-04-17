Shader "URP/ShaderBook/Chapter 10/GlassRefraction"
{
    Properties
    {
        _BaseMap("BaseMap",2D) = "white"{}
        _BumpMap("BumpMap",2D) = "bump"{}
        _CubeMap("CubeMap" ,Cube) = "_Skybox"{}
        _Distortion("Distortion",Range(0,100)) = 10     //控制模拟这是时图像的扭曲程度
        _RefractAmount("RefractAmount",Range(0,1)) = 1  //控制折射程度，当为0时，该玻璃只包含反射，当为1时，该玻璃只包含折射
    }
    SubShader
    {
        //将渲染队列设置为透明，这样其他的不透明物体都会在这个之前被渲染到屏幕上
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Transparent"}
        LOD 100

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
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0    : TEXCOORD1;
                float4 TtoW1    : TEXCOORD2;
                float4 TtoW2    : TEXCOORD3;
                float3 viewDirWS    : TEXCOORD4;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);SAMPLER(sampler_BumpMap);
            TEXTURECUBE(_CubeMap);SAMPLER(sampler_CubeMap);
            TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BumpMap_ST;
                float  _Distortion;
                float  _RefractAmount;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.uv.xy = TRANSFORM_TEX(v.texcoord, _BaseMap);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                float3 worldNormal = TransformObjectToWorldNormal(v.normalOS);
                float3 worldTangent = TransformObjectToWorldDir(v.tangentOS.xyz);
                half sign = real(v.tangentOS.w) * GetOddNegativeScale();
                float3 worldBitangent = cross(worldNormal,worldTangent) * sign;

                o.viewDirWS = GetWorldSpaceViewDir(positionWS);

                //将计算结果按列摆放得到从切线空间到世界空间的变换矩阵，将该矩阵的每一行分别存储在TtoW0、TtoW1、TtoW2中，并将世界空间下的顶点位置分别存储在了变量的W分量中
                o.TtoW0 = float4(worldTangent.x,worldBitangent.x,worldNormal.x ,positionWS.x);
                o.TtoW1 = float4(worldTangent.y,worldBitangent.y,worldNormal.y,positionWS.y);
                o.TtoW2 = float4(worldTangent.z,worldBitangent.z,worldNormal.z,positionWS.z);

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                
                half2 screenUV = i.positionHCS.xy / _ScreenParams.xy;

                //法线计算
                half4 normalMap = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap,i.uv.zw);   //切线空间
                half3 normalTS = UnpackNormal(normalMap);
                half3 worldNormal = normalize(half3(dot(i.TtoW0.xyz , normalTS),dot(i.TtoW1.xyz,normalTS),dot(i.TtoW2.xyz,normalTS)));

                half3 worldViewDir = normalize(i.viewDirWS);
                half3 reflDir = reflect(-worldViewDir,worldNormal);
                
                float2 offset = normalTS.xy *  _Distortion;
                screenUV.xy = offset + screenUV;
                half4 screenColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,screenUV);
                
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv.xy);
                half3 reflCol = SAMPLE_TEXTURECUBE(_CubeMap,sampler_CubeMap,reflDir).rgb * baseMap.rgb;

                FinalColor = half4(reflCol * (1 - _RefractAmount) + screenColor * _RefractAmount , 1.0);
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
