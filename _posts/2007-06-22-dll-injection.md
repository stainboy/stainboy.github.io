---
layout: post
title:  "DLL Injection"
date:   2007-06-22
categories: coding
summary: "First of all, let me talk about why I need to Dll injection. In recent days, I found a private server of Shininglore and downloaded it with my great curious since it’s the best and first online game that I never played before. But for some reason, the client binaries are wrapped and it force me to start a Login.exe to start game. And what really make me crazy is that when I’m playing the game, if the focus of game window lost, then the process of game will be terminated by Login.exe, which means, if I want to play game, I have to play game without doing anything else such as QQ, MSN, etc…"
---

*本文转自笔者的LiveSpace，保留了当时的写作日期*

First of all, let me talk about why I need to Dll injection. In recent days, I found a private server of Shininglore and downloaded it with my great curious since it’s the best and first online game that I never played before. But for some reason, the client binaries are wrapped and it force me to start a Login.exe to start game. And what really make me crazy is that when I’m playing the game, if the focus of game window lost, then the process of game will be terminated by Login.exe, which means, if I want to play game, I have to play game without doing anything else such as QQ, MSN, etc…

In some respect, I’m a serious person. So I decide to find a way to start game without Login.exe but I failed… Holy shit, after investigation, I found there is a way to protect process not be terminated. Generally speaking, this technology is called API Hook, which means catch the system API and return a private one. In microsoft terms, it is called "Detours". I made a HookProtect.dll by using detours which can detour every single invoke of "TerminateProcessW" in kernal32.dll. Then made a InjectDll.exe by using "Dll injection" to insert my dll into target process. Of course, dll can be injected into system process in order to trace all process but which will cost a lot of performance, so I don’t recommand it, just inject what you want.

Now, I can easily start more than one game and switch them as free as I want. By the way, during my research, I found a tool call "madCodeHook" which is made by Delphi, it’s also very useful and help me a lot.