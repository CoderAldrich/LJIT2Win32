local ffi = require "ffi"


local GDILib = ffi.load("gdi32");
local gdi32_ffi = require "gdi32_ffi"


ffi.cdef[[
typedef struct {
	HDC		Handle;
} DeviceContext;

]]

DeviceContext = ffi.typeof("DeviceContext");



local GDI32 = {
	FFI = gdi32_ffi,

	CreateDC = function(lpszDriver, lpszDevice, lpszOutput, lpInitData)
		return DeviceContext(GDILib.CreateDCA(lpszDriver, lpszDevice, lpszOutput, lpInitData));
	end,

	CreateCompatibleDC = function(hdc)
		return DeviceContext(GDILib.CreateCompatibleDC(hdc));
	end,

	CreateDCForDefaultDisplay = function(self)
		return DeviceContext(GDILib.CreateDCA("DISPLAY", nil, nil, nil));
	end,

	CreateDCForMemory = function()
		local displayDC = GDILib.CreateDCA("DISPLAY", nil, nil, nil)
		return GDIContext(GDILib.CreateCompatibleDC(displayDC))
	end,

	GetDC = function(hWnd)
		return DeviceContext(GDILib.GetDC(hWnd));
	end,

	SaveDC = function(hdc)
		return GDILib.SaveDC(hdc);
	end,

	RestoreDC = function(hdc, nSaveDC)
		return GDILib.RestoreDC(hdc, nSavedDC);
	end,


	-- Object Management
	GetObject = function(hgdiobj, cbBuffer, lpvObject)
		return GDILib.GetObjectA(hgdiobj, cbBuffer, lpvObject);
	end,

	GetStockObject = function(fnObject)
		return GDILib.GetStockObject(fnObject);
	end,


	-- Bitmaps
	CreateCompatibleBitmap = function(hdc, nWidth, nHeight)
		return GDILib.CreateCompatibleBitmap(hdc, nWidth, nHeight);
	end,

	CreateDIBSection = function(hdc, pbmi, iUsage, ppvBits, hSection, dwOffset)
		return GDILib.CreateDIBSection(hdc, pbmi, iUsage, ppvBits, hSection, dwOffset);
	end,

}





DeviceContext_mt = {
	__tostring = function(self)
		return string.format("DeviceContext(0x%s)", tostring(self.Handle))
	end,

	__index = {
		TypeName = "DeviceContext",

		Size = ffi.sizeof("DeviceContext"),


		CreateCompatibleDC = function(self)
			return DeviceContext(GDILib.CreateCompatibleDC(self.Handle))
		end,

		CreateCompatibleBitmap = function(self, width, height)
			local bm = GDIBitmap(GDILib.CreateCompatibleBitmap(self.Handle,width,height));
			bm:Init(self.Handle)

			return bm
		end,


		-- Device Context State
		Flush = function(self)
			return GDILib.GdiFlush()
		end,

		-- Object Management
		SelectObject = function(self, gdiobj)
			GDILib.SelectObject(self.Handle, gdiobj.Handle)
		end,

		SelectStockObject = function(self, objectIndex)
            -- First get a handle on the object
            local objHandle = GDILib.GetStockObject(objectIndex);

            --  Then select it into the device context
            return GDILib.SelectObject(self.Handle, objHandle);
        end,


		-- Drawing Attributes
		UseDCBrush = function(self)
			self:SelectStockObject(gdi_ffi.DC_BRUSH)
		end,

		UseDCPen = function(self)
			self:SelectStockObject(gdi_ffi.DC_PEN)
		end,

		SetDCBrushColor = function(self, color)
			return GDILib.SetDCBrushColor(self.Handle, color)
		end,

		SetDCPenColor = function(self, color)
			return GDILib.SetDCPenColor(self.Handle, color)
		end,


		-- Drawing routines
		MoveTo = function(self, x, y)
			local result = GDILib.MoveToEx(self.Handle, x, y, nil);
			return result
		end,

		MoveToEx = function(self, x, y, lpPoint)
			return GDILib.MoveToEx(self.Handle, X, Y, lpPoint);
		end,

		SetPixel = function(self, x, y, color)
			return GDILib.SetPixel(self.Handle, x, y, color);
		end,

		SetPixelV = function(self, x, y, crColor)
			return GDILib.SetPixelV(self.Handle, X, Y, crColor);
		end,

		LineTo = function(self, xend, yend)
			local result = GDILib.LineTo(self.Handle, xend, yend);
			return result
		end,

		Ellipse = function(self, nLeftRect, nTopRect, nRightRect, nBottomRect)
			return GDILib.Ellipse(self.Handle,nLeftRect,nTopRect,nRightRect,nBottomRect);
		end,

		Rectangle = function(self, left, top, right, bottom)
			return GDILib.Rectangle(self.Handle, left, top, right, bottom);
		end,

		RoundRect = function(self, left, top, right, bottom, width, height)
			return GDILib.RoundRect(self.Handle, left, top, right, bottom, width, height);
		end,

		-- Text Drawing
		Text = function(self, txt, x, y)
			x = x or 0
			y = y or 0
			return C.TextOutA(self.Handle, x, y, txt, string.len(txt));
		end,

		-- Bitmap drawing
		BitBlt = function(self, nXDest, nYDest, nWidth, nHeight, hdcSrc, nXSrc, nYSrc, dwRop)
			return GDILib.BitBlt(self.Handle,nXDest,nYDest,nWidth,nHeight,hdcSrc,nXSrc,nYSrc,dwRop);
		end,

		StretchDIBits = function(self, XDest, YDest, nDestWidth, nDestHeight, XSrc, YSrc, nSrcWidth, nSrcHeight, lpBits, lpBitsInfo, iUsage, dwRop)
			XDest = XDest or 0
			YDest = YDest or 0
			iUsage = iUsage or 0
			dwRop = dwRop or gdi32_ffi.SRCCOPY;

			return GDILib.StretchDIBits(hdc,XDest,YDest,nDestWidth,nDestHeight,XSrc,YSrc,nSrcWidth,nSrcHeight,lpBits,lpBitsInfo,iUsage,dwRop);
		end,

		GetDIBits = function(self, hbmp, uStartScan, cScanLines, lpvBits, lpbi, uUsage)
			return GDILib.GetDIBits(self.Handle,hbmp,uStartScan,cScanLines,lpvBits,lpbi,uUsage);
		end,

		StretchBlt = function(self, img, XDest, YDest,DestWidth,DestHeight)
			XDest = XDest or 0
			YDest = YDest or 0
			DestWidth = DestWidth or img.Width
			DestHeight = DestHeight or img.Height

			-- Draw a pixel buffer
			local bmInfo = BITMAPINFO();
			bmInfo.bmiHeader.biWidth = img.Width;
			bmInfo.bmiHeader.biHeight = img.Height;
			bmInfo.bmiHeader.biPlanes = 1;
			bmInfo.bmiHeader.biBitCount = img.BitsPerElement;
			bmInfo.bmiHeader.biClrImportant = 0;
			bmInfo.bmiHeader.biClrUsed = 0;
			bmInfo.bmiHeader.biCompression = 0;

			self:StretchDIBits(XDest,YDest,DestWidth,DestHeight,
				0,0,img.Width, img.Height,
				img.Data,
				bmInfo);
		end,
	}
}
DeviceContext = ffi.metatype(DeviceContext, DeviceContext_mt)


ffi.cdef[[


typedef struct {
	void * Handle;
	BITMAP	Bitmap;
	unsigned char * Pixels;
} GDIBitmap;


]]


-- For Color
-- 0x00bbggrr
function RGB(byRed, byGreen, byBlue)
	local acolor = lshift(byBlue,16) + lshift(byGreen,8) + byRed;
	return acolor;
end

function GetRValue(c)
	return band(c, 0xff)
end

function GetGValue(c)
	return band(rshift(c,8), 0xff)
end

function GetBValue(c)
	return band(rshift(c,16), 0xff)
end

--
-- This function answers the question:
-- Given:
--		We know the size of the byte boundary we want
--		to align to.
-- Question:
--		How many bytes need to be allocated to ensure we
--		will align to that boundary.
-- Discussion:
--		This comes up in cases where you're allocating a bitmap image
--		for example.  It may be a 24-bit image, but you need to ensure
--		that each row can align to a 32-bit boundary.  So, we need to
--		essentially scale up the number of bits to match the alignment.
--
local function GetAlignedByteCount(width, bitsperpixel, alignment)

	local bytesperpixel = bitsperpixel / 8;
	local stride = band((width * bytesperpixel + (alignment - 1)), bnot(alignment - 1));

	return stride;
end










BITMAP = ffi.typeof("BITMAP")

GDIBitmap = nil
GDIBitmap_mt = {
	__tostring = function(self) return string.format("GDIBitmap(0x%s)", tostring(self.Handle)) end,
	__index = {
		TypeName = "BITMAP",
		Size = ffi.sizeof("GDIBitmap"),
		Init = function(self, hdc)
			local bmap = ffi.new("BITMAP[1]")
			local bmapsize = ffi.sizeof("BITMAP");
			C.GetObjectA(self.Handle, bmapsize, bmap)
			self.Bitmap = bmap[0]

			end,

		Print = function(self)
			print(string.format("Bitmap"))
			print(string.format("        type: %d", self.Bitmap.bmType))
			print(string.format("       width: %d", self.Bitmap.bmWidth))
			print(string.format("      height: %d", self.Bitmap.bmHeight))
			print(string.format(" Width Bytes: %d", self.Bitmap.bmWidthBytes))
			print(string.format("      Planes: %d", self.Bitmap.bmPlanes))
			print(string.format("BitsPerPixel: %d", self.Bitmap.bmBitsPixel));

			end,
	}
}
GDIBitmap = ffi.metatype("GDIBitmap", GDIBitmap_mt)

--
-- GDIDIBSection_mt
--
ffi.cdef[[
typedef struct {
	void	*Handle;
	DeviceContext	hDC;
	int		Width;
	int		Height;
	int		BitsPerPixel;
	char * Pixels;
	BITMAPINFO	Info;
} GDIDIBSection;
]]

GDIDIBSection = nil
GDIDIBSection_mt = {
	__index = {
		TypeName = "GDIDIBSection",
		Size = ffi.sizeof("GDIDIBSection"),
		Init = function(self, width, height, bitsperpixel, alignment)
			alignment = alignment or 2
			bitsperpixel = bitsperpixel or 32

			self.Width = width
			self.Height = height
			self.BitsPerPixel = bitsperpixel


			-- Need to construct a BITMAPINFO structure
			-- to describe the image we'll be creating
			local bytesPerRow = GetAlignedByteCount(width, bitsperpixel, alignment)
			local info = BITMAPINFO();
			info.bmiHeader.biWidth = width
			info.bmiHeader.biHeight = height
			info.bmiHeader.biPlanes = 1
			info.bmiHeader.biBitCount = bitsperpixel
			info.bmiHeader.biSizeImage = bytesPerRow * height
			info.bmiHeader.biClrImportant = 0
			info.bmiHeader.biClrUsed = 0
			info.bmiHeader.biCompression = 0	-- GDI32.BI_RGB
			self.Info = info

			-- Create the DIBSection, using the screen as
			-- the source DC
			local ddc = GDIContext():CreateForDefaultDisplay().Handle
			local DIB_RGB_COLORS = 0
			local pixelP = ffi.new("uint8_t *[1]")
			self.Handle = GDILib.CreateDIBSection(ddc,
                info,
				DIB_RGB_COLORS,
				pixelP,
				nil,
				0);
--print("GDIDIBSection Handle: ", self.Handle)
			--self.Pixels = ffi.cast("Ppixel_BGRA_b", pixelP[0])
			self.Pixels = pixelP[0]

			-- Create a memory device context
			-- and select the DIBSecton handle into it
			self.hDC = GDIContext():CreateForMemory()
			local selected = GDILib.SelectObject(self.hDC.Handle, self.Handle)

			return self
		end,

		Print = function(self)
			print("Bits Per Pixel: ", self.BitsPerPixel)
			print("Size: ", self.Width, self.Height)
			print("Pixels: ", self.Pixels)
		end,
		}
}
GDIDIBSection = ffi.metatype("GDIDIBSection", GDIDIBSection_mt)



--[[
	Function Implementations
--]]







return GDI32
