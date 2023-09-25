Shader "Unlit/SmoothMin"
{
    Properties
    {
        _MainCol("MainColor",color) = (0.5,0.5,0.5,1)
        _Radius("Radius",Range(0,1)) = 0.4
        _Interp("Interp (K)",Range(0,1)) = 0.2

        _BGColor("Background",color) = (0,0,0,1)
        _Color1("Color1",color) = (1,0,0,1)
        _Color2("Color2",color) = (0,1,0,1)
        _Color3("Color2",color) = (0,0,1,1)

        _RayOrigin("Ray Origin",vector) = (0,1,-2,0)

        _FloorOffset("FloorOffset",Range(0,5)) = 5
        
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            #define SMIN_SCALE 0.167

            float _Interp;

            float smin (float a, float b)
            {
                float h = max(_Interp - abs(a - b),0);
                return min(a,b) - pow(h,3) * _Interp * SMIN_SCALE;
            }

            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define EPSILON 0.001

            float _Radius;

            float SphereDistance(float3 pos, float4 sphere)
            {
                return length(pos - sphere.xyz) - sphere.w;
            }
            
            #define EPSILON_DISTANCE 0.5

            float _FloorOffset;

            float GetDistance(float3 pos, out int ID)
            {
                //Spheres (xyz,radius)
                float4 s1 = float4(sin(_Time.w), 1 + sin(_Time.z),cos(_Time.y),_Radius + (_Radius/2) * abs(cos(_Time.x)));
                float4 s2 = float4(2 * sin(_Time.x), 1 + sin(_Time.y)/2, 2 * sin(_Time.z),_Radius + (_Radius/2) * abs(cos(_Time.w)));
                float4 s3 = float4(cos(_Time.y), 1 + cos(_Time.z), cos(_Time.x), _Radius + (_Radius/2) * abs(sin(_Time.z)));

                float d1 = SphereDistance(pos,s1);
                float d2 = SphereDistance(pos,s2);
                float d3 = SphereDistance(pos,s3);
                float dPlane = abs(pos.y + _FloorOffset); //PLANE

                float d = smin(smin(smin(d1,dPlane),d2),d3);
                
                ID = -1;
                if(abs(d1 - d) < EPSILON_DISTANCE) ID = 0;
                else if(abs(d2 - d) < EPSILON_DISTANCE) ID = 1;
                else if(abs(d3 - d) < EPSILON_DISTANCE) ID = 2;

                return d;
                            
            }


            float March(float3 origin, float3 dir, out int ID)
            {
                float totalDistance = 0; 
                for(int i = 0; i < MAX_STEPS; ++i)
                {
                    float3 pos = origin + dir * totalDistance;
                    float dist = GetDistance(pos,ID);
                    totalDistance += dist;
                    if(totalDistance > MAX_DIST || dist < EPSILON) break;
                }
                return totalDistance;
            
            }

            float4 _BGColor;
            float4 _Color1;
            float4 _Color2;
            float4 _Color3;
            float3 _RayOrigin;

            float4 _MainLightColor;
            float3 _MainLightDirection;

            float3 Normal(float3 position)
            {
                int ID; 
                float distance = GetDistance(position,ID);
                float2 epsilon = (EPSILON,0);
                return distance - float3(GetDistance(position - epsilon.xyy,ID),  //e,0,0 (X)
                                  GetDistance(position - epsilon.yxy,ID),  //0,e,0 (Y)
                                  GetDistance(position - epsilon.yyx,ID)); //0,0,e (Z)                  
                
            }

            float4 _MainCol;


            fixed4 frag (v2f i) : SV_Target
            { 
                float3 dir = normalize(float3(i.uv,1)); 
                int ID;              
                float distance = March(_RayOrigin,dir,ID);
                float3 position = _RayOrigin + distance * dir;

                float3 invLightDir = normalize(position - _MainLightDirection);
                float3 norm = Normal(position);
                float4 light = _MainLightColor * saturate(dot(invLightDir,norm));
            
                float4 col = ID == -1 ? _BGColor : ID == 0 ? _Color1 : ID == 1 ? _Color2 : _Color3;
                return col + light;
                                                                           
            }
            ENDCG
        }
    }
}
