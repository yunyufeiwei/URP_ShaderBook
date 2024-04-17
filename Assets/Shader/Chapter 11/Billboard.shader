Shader "URP/ShaderBook/Chapter 11/Billboard"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        [Enum(Billboard,1,VerticalBillboard,0)]_BillboardType("VerticalBillboarding",Range(0,1)) = 1
    }
    SubShader
    {
        //设置渲染队列/渲染类型/忽略投射阴影/使用批处理
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProjector"="True" "DisableBatching"="True"}
        LOD 100

        Pass
        {
            //pass下面单独使用一个Tags，在光照模型只在该pass下生效
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
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 viewDirWS    : TEXCOORD1;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _BillboardType;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                //广告牌技术的计算是在模型空间下进行的，因此选择模型空间的原点作为广告牌的锚点
                float3 center = float3(0,0,0);

                //使用世界空间到模型空间的矩阵转换视角向量
                float3 viewDirWS = normalize(mul(GetWorldToObjectMatrix() , float4(_WorldSpaceCameraPos , 1.0))).xyz;

                //通过两个位置信息计算目标的法线向量
                float3 normalDir = viewDirWS - center;
                normalDir.y = normalDir.y * _BillboardType;
                normalDir = normalize(normalDir);

                //方案一：
                // float3 upDir = abs(normalDir.y) > 0.999 ? float3(0,0,1):float3(0,1,0);
                // float3 rightDir = normalize(cross(upDir,normalDir));
                // upDir = normalize(cross(normalDir,rightDir));   //重新计算右方向
                //
                // float3 centerOffs = v.positionOS.xyz - center;
                // float3 localPos = center + (rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z);

                //方案二：
                float3 upDir = float3(0,1,0);
                float3 rightDir = normalize(cross(viewDirWS,upDir));
                upDir = normalize(cross(rightDir,viewDirWS));
                float3 localPos = rightDir * v.positionOS.x + upDir * v.positionOS.y + viewDirWS * v.positionOS.z;
                
                o.positionHCS = TransformObjectToHClip(float4(localPos,1.0));
                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,i.uv);
                FinalColor = _Color * baseMap;
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
