#include "Common.hlsl"

struct STriVertex
{ // IMPORTANT - the c++ version of this is 'Vertex' found in the common.h file
    float3 vertex;
    float4 normal;
    float2 texCoord;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);
StructuredBuffer<int> indices : register(t1);

[shader("closesthit")]void ClosestHit(inout HitInfo payload, Attributes attrib)
{
    uint vertId = 3 * PrimitiveIndex();
    // vertId = the first index, vertId + 1 = the second, vertId + 2 = the third
    // e.g. BTriVertex[indices[vertId + 0]]
    
    STriVertex A = BTriVertex[indices[vertId + 0]];
    STriVertex B = BTriVertex[indices[vertId + 1]];
    STriVertex C = BTriVertex[indices[vertId + 2]];
    
    float3 barycentrics = float3(1.f - attrib.bary.x - attrib.bary.y, attrib.bary.x, attrib.bary.y);
    
    //float3 colourOut = A.color.rgb * barycentrics.x
    //                 + B.color.rgb * barycentrics.y
    //                 + C.color.rgb * barycentrics.z;
    
    float3 basicColourOut = float3(0, 1, 0);
  
    payload.colorAndDistance = float4(basicColourOut, RayTCurrent());

}
