// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/a" {
		Properties{
			_Texture("Texture",2D) = "white"{}
		}
			SubShader
			{
				Pass
				{
					CGPROGRAM
					#pragma vertex vert
					#pragma fragment frag

					sampler2D _Texture;

					struct appdata
					{
						float4 vertex : POSITION;
						float2 texcoord : TEXCOORD0;
						float3 normal : NORMAL;
					};

					struct v2f
					{
						float4 vertex : SV_POSITION;
						float2 uv : TEXCOORD0;
					};


					v2f vert(appdata v)
					{
						v2f o;
						v.vertex.x += 0.05 * v.normal.x * (sin(v.vertex.y * 3.14 * _Time.y) + 1.0);
						v.vertex.z += 0.01 * v.normal.z * (sin(v.vertex.y * 3.14 * _Time.y) + 1.0);
						o.vertex = UnityObjectToClipPos(v.vertex);
						o.uv = v.texcoord;
						return o;
					}

					fixed4 frag(v2f i) : SV_Target
					{
						fixed4 tex = tex2D(_Texture, i.uv);
						
						return tex;
					}
					ENDCG
				}
			}
	}