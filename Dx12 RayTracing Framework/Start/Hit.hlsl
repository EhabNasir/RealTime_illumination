#include "Common.hlsl"

struct STriVertex
{ // IMPORTANT - the c++ version of this is 'Vertex' found in the common.h file
    float3 vertex;
    float4 normal;
    float2 texCoord;
};

StructuredBuffer<STriVertex> BTriVertex : register(t0);
StructuredBuffer<int> indices : register(t1);

cbuffer ColourParams : register(b0)
{
    float4 colourPlane;
    float4 colourDonut;
}

RaytracingAccelerationStructure SceneBVH : register(t2);

float3 HitWorldPosition()
{
    return WorldRayOrigin() + RayTCurrent() * WorldRayDirection();
}

float3 HitAttribute(float3 vertexAttribute[3], Attributes attr)
{
    float3 barycentrics = float3(
        1.0f - attr.bary.x - attr.bary.y,
        attr.bary.x,
        attr.bary.y);
        
    return vertexAttribute[0] * barycentrics.x
         + vertexAttribute[1] * barycentrics.y
         + vertexAttribute[2] * barycentrics.z;
}

// Also add a float2 version for texture coordinates later
float2 HitAttribute2(float2 vertexAttribute[3], Attributes attr)
{
    float3 barycentrics = float3(
        1.0f - attr.bary.x - attr.bary.y,
        attr.bary.x,
        attr.bary.y);
        
    return vertexAttribute[0] * barycentrics.x
         + vertexAttribute[1] * barycentrics.y
         + vertexAttribute[2] * barycentrics.z;
}

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
    
    // Store normals in array for HitAttribute
    float3 vertexNormals[3] =
    {
        A.normal.xyz,
        B.normal.xyz,
        C.normal.xyz
    };
    
        // Get interpolated normal using barycentrics
    float3 triangleNormal = HitAttribute(vertexNormals, attrib);

    // Transform normal from model space to world space
    // Cast to float3x3 to remove translation component
    float3 worldNormal = normalize(mul(triangleNormal, (float3x3) ObjectToWorld4x3()));

    // Get world position of hit point using the ray
    float3 worldPosition = HitWorldPosition();
    
        // Define a light source position in world space
    float3 lightPosition = float3(2, 2, -2);
    
    // Calculate direction from hit point to light
    float3 lightDir = normalize(lightPosition - worldPosition);
    
    // Diffuse - dot product between normal and light direction
    // max(0) prevents negative values (surfaces facing away from light)
    float diffuse = max(dot(worldNormal, lightDir), 0.0f);
    
    // Ambient - base light so nothing is completely black
    float ambient = 0.1f;
    
    float3 viewDir = normalize(WorldRayOrigin() - worldPosition);
    float3 reflectDir = reflect(-lightDir, worldNormal);
    float shininess = 32.0f; // higher = sharper highlight
    float specular = pow(max(dot(viewDir, reflectDir), 0.0f), shininess);
    float specularStrength = 0.5f;

    // Full Phong combination
    float3 colour = colourDonut.rgb * (ambient + diffuse)
                  + float3(1, 1, 1) * specular * specularStrength;
    
    // Combine lighting with object colour
    //float3 colour = colourDonut.rgb * (diffuse + ambient);
    
    payload.colorAndDistance = float4(colour, RayTCurrent());
    
    float3 basicColourOut = float3(0, 1, 0);
  
    payload.colorAndDistance = float4(colour, RayTCurrent());

}

[shader("closesthit")]void PlaneClosestHit(inout HitInfo payload, Attributes attrib)
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
    
    float3 vertexNormals[3] =
    {
        A.normal.xyz,
        B.normal.xyz,
        C.normal.xyz
    };

    
    float3 triangleNormal = HitAttribute(vertexNormals, attrib);
    float3 worldNormal = normalize(mul(triangleNormal, (float3x3) ObjectToWorld4x3()));
    float3 worldPosition = HitWorldPosition();

    float3 lightPosition = float3(2, 2, -2);
    float3 lightDir = normalize(lightPosition - worldPosition);
    
    float diffuse = max(dot(worldNormal, lightDir), 0.0f);
    float ambient = 0.1f;
    
    float3 colour = colourPlane.rgb * (diffuse + ambient);
    
    float3 basicColourOut = float3(0, 1, 0);
    
    RayDesc shadowRay;
    shadowRay.Origin = worldPosition;
    shadowRay.Direction = normalize(lightPosition - worldPosition);
    shadowRay.TMin = 0.001f;
    shadowRay.TMax = length(lightPosition - worldPosition);

    ShadowHitInfo shadowPayload;
    shadowPayload.isHit = 0;

    TraceRay(
    SceneBVH,
    RAY_FLAG_NONE, // instance mask
    0xFF,
    1, // hit group offset = 1 (ShadowHitGroup is 1 after PlaneHitGroup)
    0, // geometry contribution multiplier
    1, // miss shader index = 1 (ShadowMiss is second miss shader)
    shadowRay,
    shadowPayload
);

    if (shadowPayload.isHit == false)
        colour *= 1.0f;
    else
        colour *= 0.2f;
    
  
    payload.colorAndDistance = float4(colour, RayTCurrent());

}

[shader("closesthit")]
void ShadowClosestHit(inout ShadowHitInfo payload, Attributes attrib)
{
    payload.isHit = true;
}