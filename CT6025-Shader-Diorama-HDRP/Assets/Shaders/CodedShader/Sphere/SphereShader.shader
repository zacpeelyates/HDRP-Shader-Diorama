Shader "Unlit/SphereShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PlaneTex("Plane Texture",2D) = "white" {}
        _Edge("Edge",Range(-0.5,0.5)) = 0
        _Radius("Radius", Range(0,0.5)) = 0.4
        _Color("Color",color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature USE_TOGGLE

            #include "UnityCG.cginc"

            #define SURFACE_EPSILON 0.001
            #define MAX_DISTANCE 10.0
            #define MAX_STEPS 50

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 hit : POSITION1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _PlaneTex;
            float4 _PlaneTex_ST;

            float4 _Color;
            float _Radius;
            float _Edge;

            float sphereCast(float3 origin, float3 dir)
            {
                float dTotal = 0; 
                for(int i = 0; i < MAX_STEPS; ++i)
                {
                    float3 ray = origin + dir * dTotal;
                    float d = ray.y - _Edge;
                    dTotal += d;
                    if(d > MAX_STEPS  || dTotal < SURFACE_EPSILON) break;                   
                }
                return dTotal;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.hit = v.vertex;
                return o;
            }

            #define SMOOTHSTEP_EPSILON 0.01

            fixed4 frag (v2f i, bool f : SV_ISFRONTFACE) : SV_Target
            {
                if(i.hit.y  > _Edge) discard;

                float3 cameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                float3 dir = normalize(i.hit - cameraPos);
                float dist = sphereCast(cameraPos,dir); //spherecast from camerapos in dir

                fixed4 col = tex2D(_MainTex,i.uv);
                fixed4 pCol = col;


                if(dist < MAX_DISTANCE)
                {
                    //slice 
                    float3 planePos = cameraPos + dir * dist; //position of plane
       
                    float2 planeUV = planePos.xz;
                    float e = abs(_Edge);
                    float UVScale = pow(e,2) + pow(e + 1, 2);
                    UVScale = 1 - pow(_Edge * UVScale,2);
                    pCol = tex2D(_PlaneTex,planeUV * UVScale - 0.5);

                    //radius
                    float UVLength = length(planeUV);
                    float r = _Radius - pow(e,2);
                    float4 rad = smoothstep(UVLength - SMOOTHSTEP_EPSILON, UVLength + SMOOTHSTEP_EPSILON, r);
                    pCol *= rad;
                    pCol += (1-rad) * _Color;
                                               
                }

                return f ? col : pCol; 
            }
        
            ENDCG
        }
    }
}
