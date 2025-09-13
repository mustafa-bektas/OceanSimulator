Shader "Custom/WaterShader"
{
    Properties
    {
        _Amplitude ("Wave Amplitude", Range(0, 2)) = 0.5
        _Frequency ("Wave Frequency", Range(0, 10)) = 2.0
        _Speed ("Wave Speed", Range(0, 5)) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float3 worldPos : TEXCOORD0;
            };

            float _Amplitude;
            float _Frequency;
            float _Speed;
            
            float3 calculateWaveNormal(float3 pos)
            {
                float time = _Time.y;

                float dFdx = 
                    cos(pos.x * _Frequency * 0.8 + pos.z * _Frequency * 0.6 + time * _Speed) * _Frequency * 0.8 * _Amplitude * 0.6 +
                    cos(pos.x * _Frequency * 1.2 + pos.z * _Frequency * 0.4 + time * _Speed * 0.8) * _Frequency * 1.2 * _Amplitude * 0.4 +
                    cos(pos.x * _Frequency * 0.5 + pos.z * _Frequency * 1.1 + time * _Speed * 1.3) * _Frequency * 0.5 * _Amplitude * 0.8 +
                    cos(pos.x * _Frequency * 0.3 + pos.z * _Frequency * 0.7 + time * _Speed * 0.6) * _Frequency * 0.3 * _Amplitude * 0.3;
                
                float dFdz = 
                    cos(pos.x * _Frequency * 0.8 + pos.z * _Frequency * 0.6 + time * _Speed) * _Frequency * 0.6 * _Amplitude * 0.6 +
                    cos(pos.x * _Frequency * 1.2 + pos.z * _Frequency * 0.4 + time * _Speed * 0.8) * _Frequency * 0.4 * _Amplitude * 0.4 +
                    cos(pos.x * _Frequency * 0.5 + pos.z * _Frequency * 1.1 + time * _Speed * 1.3) * _Frequency * 1.1 * _Amplitude * 0.8 +
                    cos(pos.x * _Frequency * 0.3 + pos.z * _Frequency * 0.7 + time * _Speed * 0.6) * _Frequency * 0.7 * _Amplitude * 0.3;
                
                float3 normal = normalize(float3(-dFdx, 1.0, -dFdz));
                return normal;

            }

            v2f vert (appdata v)
            {
                v2f o;

                float wave0 = sin(v.vertex.x * _Frequency * 0.8 + v.vertex.z * _Frequency * 0.6 + _Time.y * _Speed) * _Amplitude * 0.6;
                float wave1 = sin(v.vertex.x * _Frequency * 1.2 + v.vertex.z * _Frequency * 0.4 + _Time.y * _Speed * 0.8) * _Amplitude * 0.4;
                float wave2 = sin(v.vertex.x * _Frequency * 0.5 + v.vertex.z * _Frequency * 1.1 + _Time.y * _Speed * 1.3) * _Amplitude * 0.8;
                float wave3 = sin(v.vertex.x * _Frequency * 0.3 + v.vertex.z * _Frequency * 0.7 + _Time.y * _Speed * 0.6) * _Amplitude * 0.3;
                float wavesum = wave0 + wave1 + wave2 + wave3;
                v.vertex.y += wavesum;
                
                o.normal = calculateWaveNormal(v.vertex.xyz);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = max(0, dot(i.normal, lightDir));
                
                fixed3 waterColor = fixed3(0.1, 0.4, 1.0);
                fixed3 litColor = waterColor * NdotL; // ambient
                
                return fixed4(litColor, 1.0);
            }
            ENDCG
        }
    }
}