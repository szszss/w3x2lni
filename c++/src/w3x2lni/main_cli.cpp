﻿#include "common.h"
#include <stdio.h>
#include <string>
#include "../lua/lua.hpp"
extern "C" {
#include "../utf8/unicode.h"
}

struct luaparse {
	luaparse()
		: L(luaL_newstate()) {
	}
	~luaparse() {
		if (L) lua_close(L);
	}
	bool loadstring(const std::string& str) {
		if (luaL_loadstring(L, str.c_str()) || lua_pcall(L, 0, 1, 0)) {
			lua_pop(L, 1);
			return false;
		}
		return true;
	}
	operator lua_State*() {
		return L;
	}
	lua_State* L;
};

class console {
private:
	HANDLE handle;
public:
	console()
		: handle(GetStdHandle(STD_OUTPUT_HANDLE))
	{ }
	COORD getxy() {
		CONSOLE_SCREEN_BUFFER_INFO screenBufferInfo;
		if (GetConsoleScreenBufferInfo(handle, &screenBufferInfo) == 0) {
			return { 0 };
		}
		COORD position;
		position.X = screenBufferInfo.dwCursorPosition.X;
		position.Y = screenBufferInfo.dwCursorPosition.Y;
		return position;
	}
	void setxy(COORD position) {
		::SetConsoleCursorPosition(handle, position);
	}
	void setxy(int x, int y) {
		setxy({ (SHORT)x, (SHORT)y });
	}
	void color(int x) {
		SetConsoleTextAttribute(handle, x);
	}
	void text(const std::wstring& buf) {
		text(buf.data(), buf.size());
	}
	void text(const wchar_t* buf, size_t len = 0) {
		DWORD wlen = 0;
		WriteConsoleW(handle, buf, len ? len : wcslen(buf), &wlen, 0);
	}
	void text(const char* buf, size_t len = 0) {
		text(u2w(buf));
	}
};

struct protocol {
	int stat = 0;
	size_t need = 0;
	std::string buf;
	luaparse L;
	console  console;
	COORD    basepos;
	protocol()
		: console()
		, basepos(console.getxy())
	{
		console.setxy({ 0, basepos.Y });
		console.text(L"");
		console.setxy({ 0, basepos.Y + 1 });
		printf("%3d%%", 0);
		console.text(L"[>-------------------]");
	}

	~protocol()
	{
		console.setxy({ 0, basepos.Y + 2 });
	}

	bool unpack(const char* str, size_t len) {
		for (size_t i = 0; i < len; ++i)
		{
			char c = str[i];
			buf.push_back(c);
			switch (stat)
			{
			case 0:
				if (c == '\r') stat = 1;
				break;
			case 1:
				stat = 0;
				if (c == '\n') {
					if (buf.substr(0, 16) != "Content-Length: ") {
						return false;
					}
					try {
						need = (size_t)std::stol(buf.substr(16, buf.size() - 18));
						stat = 2;
					}
					catch (...) {
						return false;
					}
					buf.clear();
				}
				break;
			case 2:
				if (buf.size() >= need)
				{
					if (!messsage(buf.substr(0, need))) {
						return false;
					}
					buf.clear();
					stat = 0;
				}
				break;
			}
		}
		return true;
	}

	bool messsage(const std::string& str) {
		if (!L.loadstring("return " + str)) {
			return false;
		}
		if (LUA_TSTRING == lua_getfield(L, -1, "type")) {
			std::string type = lua_tostring(L, -1);
			lua_pop(L, 1);
			if (type == "progress") {
				msg_progress();
			}
			else if (type == "text") {
				msg_text();
			}
		}
		else {
			lua_pop(L, 1);
		}
		lua_pop(L, 1);
		return true;
	}

	void msg_progress() {
		if (LUA_TNUMBER == lua_getfield(L, -1, "args")) {
			int value = (int)(100 * lua_tonumber(L, -1));
			console.setxy({ 0, basepos.Y + 1 });
			printf("%3d%%", value);
			std::wstring progress = L"[";
			for (int i = 0; i < value / 5; ++i) {
				progress += L"=";
			}
			if (value < 95) {
				progress += L">";
			}
			for (int i = 0; i < 19 - value / 5; ++i) {
				progress += L"-";
			}
			progress += L"]";
			console.text(progress);
		}
		lua_pop(L, 1);
	}

	void msg_text() {
		if (LUA_TSTRING == lua_getfield(L, -1, "args")) {
			console.setxy({ 0, basepos.Y });
			console.text(L"                                        ");
			console.setxy({ 0, basepos.Y });
			console.text(lua_tostring(L, -1));
		}
		lua_pop(L, 1);
	}
	void msg_error(const char* buf) {
		console.setxy({ 0, basepos.Y + 2 });
		console.text(buf);
		console.text(L"\r\n");
		basepos = console.getxy();
		basepos.Y -= 2;
	}
};

int __cdecl wmain()
{
	pipe out, err;
	if (!out.open('r')) {
		return -1;
	}
	if (!err.open('r')) {
		return -1;
	}

	if (!execute_lua(L"CLI", &out, &err)) {
		return -1;
	}

	protocol proto;
	char outbuf[2048];
	char errbuf[2048];
	size_t errpos = 0;
	for (;;) {
		size_t outlen = out.read(outbuf, sizeof outbuf);
		size_t errlen = err.read(errbuf + errpos, sizeof errbuf - errpos - 1);
		if (outlen == -1 && errlen == -1) {
			break;
		}
		if (outlen == 0 && errlen == 0) {
			Sleep(200);
			continue;
		}
		if (outlen != 0 && outlen != -1) {
			proto.unpack(outbuf, outlen);
		}
		if (errlen != 0 && errlen != -1) {
			errpos += errlen;
		}
	}
	if (errpos) {
		errbuf[errpos] = 0;
		proto.msg_error(errbuf);
	}
	return 0;
}