#include "stdafx.h"
#include "DrawableGameObject.h"


using namespace std;

//#define NUM_VERTICES 36

DrawableGameObject::DrawableGameObject()
{
	//m_pVertexBuffer = nullptr;
	//m_pIndexBuffer = nullptr;
	//m_pTextureResourceView = nullptr;
	//m_pSamplerLinear = nullptr;

	// Initialize the world matrix
	XMStoreFloat4x4(&m_World, XMMatrixIdentity());
	m_position = XMFLOAT3(0, 0, 0);
}


DrawableGameObject::~DrawableGameObject()
{
	cleanup();
}

void DrawableGameObject::cleanup()
{
	// TODO
	//if (m_pVertexBuffer)
	//	m_pVertexBuffer->Release();
	//m_pVertexBuffer = nullptr;

	//if (m_pIndexBuffer)
	//	m_pIndexBuffer->Release();
	//m_pIndexBuffer = nullptr;

	//if (m_pTextureResourceView)
	//	m_pTextureResourceView->Release();
	//m_pTextureResourceView = nullptr;

	//if (m_pSamplerLinear)
	//	m_pSamplerLinear->Release();
	//m_pSamplerLinear = nullptr;

	//if (m_pMaterialConstantBuffer)
	//	m_pMaterialConstantBuffer->Release();
	//m_pMaterialConstantBuffer = nullptr;
}

HRESULT DrawableGameObject::initMesh(ComPtr<ID3D12Device5> device)
{
	// Create the vertex buffer.
	{
													//  U     V
													//(0, 0)(1, 0)
													//(0, 1)(1, 1)
		// Define the geometry for a triangle.
		Vertex triangleVertices[] = {
			{{0.0f, 0.25f * 1.0f, 0.0f}, {0, 0, 1, 0}, {0.5f, 0} },
			{{0.25f, -0.25f * 1.0f, 0.0f}, {0, 0, 1, 0}, {1, 1} },
			{{-0.25f, -0.25f * 1.0f, 0.0f}, {0, 0, 1, 0}, {0, 1}} };

		m_vertexCount = 3;

		const UINT vertexBufferSize = sizeof(triangleVertices);

		// Note: using upload heaps to transfer static data like vert buffers is not
		// recommended. Every time the GPU needs it, the upload heap will be
		// marshalled over. Please read up on Default Heap usage. An upload heap is
		// used here for code simplicity and because there are very few verts to
		// actually transfer.
		ThrowIfFailed(device->CreateCommittedResource(
			&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD), D3D12_HEAP_FLAG_NONE,
			&CD3DX12_RESOURCE_DESC::Buffer(vertexBufferSize),
			D3D12_RESOURCE_STATE_GENERIC_READ, nullptr,
			IID_PPV_ARGS(&m_vertexBuffer)));

		// Copy the triangle data to the vertex buffer.
		UINT8* pVertexDataBegin;
		CD3DX12_RANGE readRange(
			0, 0); // We do not intend to read from this resource on the CPU.
		ThrowIfFailed(m_vertexBuffer->Map(
			0, &readRange, reinterpret_cast<void**>(&pVertexDataBegin)));
		memcpy(pVertexDataBegin, triangleVertices, sizeof(triangleVertices));
		m_vertexBuffer->Unmap(0, nullptr);
	}


	// create the index buffer
	{
		// indices.
		UINT indices[] =
		{
			0,1,2,
		};

		m_indexCount = sizeof(indices) / sizeof(UINT);

		const UINT indexBufferSize = sizeof(indices);
		CD3DX12_HEAP_PROPERTIES heapProperty = CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD);
		CD3DX12_RESOURCE_DESC bufferResource = CD3DX12_RESOURCE_DESC::Buffer(indexBufferSize);
		ThrowIfFailed(device->CreateCommittedResource(
			&heapProperty, D3D12_HEAP_FLAG_NONE, &bufferResource, //
			D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, IID_PPV_ARGS(&m_indexBuffer)));

		// Copy the triangle data to the index buffer.
		CD3DX12_RANGE readRange(0, 0); // We do not intend to read from this resource on the CPU.

		UINT8* pIndexDataBegin;
		ThrowIfFailed(m_indexBuffer->Map(0, &readRange, reinterpret_cast<void**>(&pIndexDataBegin)));
		memcpy(pIndexDataBegin, indices, indexBufferSize);
		m_indexBuffer->Unmap(0, nullptr);
	}


	return S_OK;
}

HRESULT DrawableGameObject::initPlaneMesh(ComPtr<ID3D12Device5> device)
{
	// Create the vertex buffer.
	{
		//  U     V
		//(0, 0)(1, 0)
		//(0, 1)(1, 1)

		float diameter = 0.5f;
// Define the geometry for a plane.
		Vertex planeVertices[] = {
			{{-diameter, diameter, 0.0f}, {0, 0, 1, 0}, {0.5f, 0} },
			{{-diameter, -diameter, 0.0f}, {0, 0, 1, 0}, {1, 1} },
			{{diameter, diameter, 0.0f}, {0, 0, 1, 0}, {0, 1}},
			{{diameter, -diameter, 0.0f}, {0, 0, 1, 0}, {0, 1}}
		};

		m_vertexCount = 4;

		const UINT vertexBufferSize = sizeof(planeVertices);

		// Note: using upload heaps to transfer static data like vert buffers is not
		// recommended. Every time the GPU needs it, the upload heap will be
		// marshalled over. Please read up on Default Heap usage. An upload heap is
		// used here for code simplicity and because there are very few verts to
		// actually transfer.
		ThrowIfFailed(device->CreateCommittedResource(
			&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD), D3D12_HEAP_FLAG_NONE,
			&CD3DX12_RESOURCE_DESC::Buffer(vertexBufferSize),
			D3D12_RESOURCE_STATE_GENERIC_READ, nullptr,
			IID_PPV_ARGS(&m_vertexBuffer)));

		// Copy the triangle data to the vertex buffer.
		UINT8* pVertexDataBegin;
		CD3DX12_RANGE readRange(
			0, 0); // We do not intend to read from this resource on the CPU.
		ThrowIfFailed(m_vertexBuffer->Map(
			0, &readRange, reinterpret_cast<void**>(&pVertexDataBegin)));
		memcpy(pVertexDataBegin, planeVertices, sizeof(planeVertices));
		m_vertexBuffer->Unmap(0, nullptr);
	}


	// create the index buffer
	{
		// indices.
		UINT indices[] =
		{
			0,1,2,
			2,1,3,
		};

		m_indexCount = sizeof(indices) / sizeof(UINT);

		const UINT indexBufferSize = sizeof(indices);
		CD3DX12_HEAP_PROPERTIES heapProperty = CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD);
		CD3DX12_RESOURCE_DESC bufferResource = CD3DX12_RESOURCE_DESC::Buffer(indexBufferSize);
		ThrowIfFailed(device->CreateCommittedResource(
			&heapProperty, D3D12_HEAP_FLAG_NONE, &bufferResource, //
			D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, IID_PPV_ARGS(&m_indexBuffer)));

		// Copy the triangle data to the index buffer.
		CD3DX12_RANGE readRange(0, 0); // We do not intend to read from this resource on the CPU.

		UINT8* pIndexDataBegin;
		ThrowIfFailed(m_indexBuffer->Map(0, &readRange, reinterpret_cast<void**>(&pIndexDataBegin)));
		memcpy(pIndexDataBegin, indices, indexBufferSize);
		m_indexBuffer->Unmap(0, nullptr);
	}

	m_MeshData.VertexBuffer = m_vertexBuffer;
	m_MeshData.IndexBuffer = m_indexBuffer;
	m_MeshData.VertexCount = m_vertexCount;
	m_MeshData.IndexCount = m_indexCount;

	return S_OK;
}

HRESULT DrawableGameObject::initCubeMesh(ComPtr<ID3D12Device5> device)
{
	// Create the vertex buffer.
	{
		//  U     V
		//(0, 0)(1, 0)
		//(0, 1)(1, 1)

		float diameter = 0.5f;
		// Define the geometry for a plane.
		Vertex cubeVertices[] = {
			// Front face
			{{-diameter,  diameter,  diameter}, {0, 0,  1, 0}, {0.0f, 0.0f}},
			{{-diameter, -diameter,  diameter}, {0, 0,  1, 0}, {0.0f, 1.0f}},
			{{ diameter,  diameter,  diameter}, {0, 0,  1, 0}, {1.0f, 0.0f}},
			{{ diameter, -diameter,  diameter}, {0, 0,  1, 0}, {1.0f, 1.0f}},

			// Back face
			{{ diameter,  diameter, -diameter}, {0, 0, -1, 0}, {0.0f, 0.0f}},
			{{ diameter, -diameter, -diameter}, {0, 0, -1, 0}, {0.0f, 1.0f}},
			{{-diameter,  diameter, -diameter}, {0, 0, -1, 0}, {1.0f, 0.0f}},
			{{-diameter, -diameter, -diameter}, {0, 0, -1, 0}, {1.0f, 1.0f}},

			// Left face
			{{-diameter,  diameter, -diameter}, {-1, 0, 0, 0}, {0.0f, 0.0f}},
			{{-diameter, -diameter, -diameter}, {-1, 0, 0, 0}, {0.0f, 1.0f}},
			{{-diameter,  diameter,  diameter}, {-1, 0, 0, 0}, {1.0f, 0.0f}},
			{{-diameter, -diameter,  diameter}, {-1, 0, 0, 0}, {1.0f, 1.0f}},

			// Right face
			{{ diameter,  diameter,  diameter}, {1, 0, 0, 0}, {0.0f, 0.0f}},
			{{ diameter, -diameter,  diameter}, {1, 0, 0, 0}, {0.0f, 1.0f}},
			{{ diameter,  diameter, -diameter}, {1, 0, 0, 0}, {1.0f, 0.0f}},
			{{ diameter, -diameter, -diameter}, {1, 0, 0, 0}, {1.0f, 1.0f}},

			// Top face
			{{-diameter,  diameter, -diameter}, {0, 1, 0, 0}, {0.0f, 0.0f}},
			{{-diameter,  diameter,  diameter}, {0, 1, 0, 0}, {0.0f, 1.0f}},
			{{ diameter,  diameter, -diameter}, {0, 1, 0, 0}, {1.0f, 0.0f}},
			{{ diameter,  diameter,  diameter}, {0, 1, 0, 0}, {1.0f, 1.0f}},

			// Bottom face
			{{-diameter, -diameter,  diameter}, {0, -1, 0, 0}, {0.0f, 0.0f}},
			{{-diameter, -diameter, -diameter}, {0, -1, 0, 0}, {0.0f, 1.0f}},
			{{ diameter, -diameter,  diameter}, {0, -1, 0, 0}, {1.0f, 0.0f}},
			{{ diameter, -diameter, -diameter}, {0, -1, 0, 0}, {1.0f, 1.0f}},
		};

		m_vertexCount = 24;

		const UINT vertexBufferSize = sizeof(cubeVertices);

		// Note: using upload heaps to transfer static data like vert buffers is not
		// recommended. Every time the GPU needs it, the upload heap will be
		// marshalled over. Please read up on Default Heap usage. An upload heap is
		// used here for code simplicity and because there are very few verts to
		// actually transfer.
		ThrowIfFailed(device->CreateCommittedResource(
			&CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD), D3D12_HEAP_FLAG_NONE,
			&CD3DX12_RESOURCE_DESC::Buffer(vertexBufferSize),
			D3D12_RESOURCE_STATE_GENERIC_READ, nullptr,
			IID_PPV_ARGS(&m_vertexBuffer)));

		// Copy the triangle data to the vertex buffer.
		UINT8* pVertexDataBegin;
		CD3DX12_RANGE readRange(
			0, 0); // We do not intend to read from this resource on the CPU.
		ThrowIfFailed(m_vertexBuffer->Map(
			0, &readRange, reinterpret_cast<void**>(&pVertexDataBegin)));
		memcpy(pVertexDataBegin, cubeVertices, sizeof(cubeVertices));
		m_vertexBuffer->Unmap(0, nullptr);
	}


	// create the index buffer
	{
		// indices.
		UINT indices[] =
		{
			0,  1,  2,   2,  1,  3,   // front
			4,  5,  6,   6,  5,  7,   // back
			8,  9,  10,  10, 9,  11,  // left
			12, 13, 14,  14, 13, 15,  // right
			16, 17, 18,  18, 17, 19,  // top
			20, 21, 22,  22, 21, 23,  // bottom
		};

		m_indexCount = sizeof(indices) / sizeof(UINT);

		const UINT indexBufferSize = sizeof(indices);
		CD3DX12_HEAP_PROPERTIES heapProperty = CD3DX12_HEAP_PROPERTIES(D3D12_HEAP_TYPE_UPLOAD);
		CD3DX12_RESOURCE_DESC bufferResource = CD3DX12_RESOURCE_DESC::Buffer(indexBufferSize);
		ThrowIfFailed(device->CreateCommittedResource(
			&heapProperty, D3D12_HEAP_FLAG_NONE, &bufferResource, //
			D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, IID_PPV_ARGS(&m_indexBuffer)));

		// Copy the triangle data to the index buffer.
		CD3DX12_RANGE readRange(0, 0); // We do not intend to read from this resource on the CPU.

		UINT8* pIndexDataBegin;
		ThrowIfFailed(m_indexBuffer->Map(0, &readRange, reinterpret_cast<void**>(&pIndexDataBegin)));
		memcpy(pIndexDataBegin, indices, indexBufferSize);
		m_indexBuffer->Unmap(0, nullptr);
	}


	return S_OK;
}

HRESULT DrawableGameObject::initOBJMesh(ComPtr<ID3D12Device5> device, char* szOBJName)
{
	m_MeshData = OBJLoader::Load(szOBJName, device.Get());
	assert(m_MeshData.VertexBuffer);
	return S_OK;
}

DrawableGameObject* DrawableGameObject::createCopy()
{
	DrawableGameObject* pobj = new DrawableGameObject();
	*pobj = *this;
	return pobj;
}

void DrawableGameObject::setPosition(XMFLOAT3 position)
{
	m_position = position;
}

void DrawableGameObject::update(float t)
{
	static float cummulativeTime = 0;
	//cummulativeTime += t;
	// Cube: Rotate around origin
	XMMATRIX mSpin = XMMatrixRotationY(cummulativeTime);
	XMMATRIX mScale = XMMatrixScaling(m_scale, m_scale, m_scale);
	XMMATRIX mTranslate = XMMatrixTranslation(m_position.x, m_position.y, m_position.z);

	//Apply Transformations
	XMMATRIX world = mTranslate * mSpin * mScale;

	XMStoreFloat4x4(&m_World, world);
}
