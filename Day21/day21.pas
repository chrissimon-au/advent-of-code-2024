
Program day21;

{$mode objfpc}{$H+}

Uses 
Classes,
SysUtils,
Types,
StrUtils,
StrHashMap,
CacheEntry,
TextTestRunner,
TestFramework;

Type 
  Pos = Record
    Col : int64;
    Row : int64;
  End;

  StringArray = array Of string;

  OptionsArray = array Of StringArray;

  TGetKeyPressFunc = Function (start: String;
                               target: String;
                               numRobots: int64;
                               cache: TStringHashMap): String;

Const 
  NumKpBlankPos : Pos = (Col: 0; Row: 3);
  DirKpBlankPos : Pos = (Col: 0; Row: 0);

Function GetEntryKeyPressCount(startChar: char;
                               targetChar: char;
                               numRobots: int64;
                               getKeyPressFunc: TGetKeyPressFunc;
                               cache: TStringHashMap): int64;
forward;

Function GetDirKpStepPresses (start: String;
                              target: String;
                              numRobots: int64;
                              cache: TStringHashMap): String;
forward;

(* Routines *)
Function PosToString(pos: Pos) : String;

Var ColStr, RowStr: String;
Begin
  Str(pos.Col, ColStr);
  Str(pos.Row, RowStr);
  PosToString := '(' + ColStr + ',' + RowStr + ')';
End;

Function PosDiff(posL: Pos; posR: Pos) : int64;
Begin
  PosDiff := abs(posL.Col-posR.Col) + abs(posL.Row-posR.row);
End;

Function GetDirKpPos (button : String) : Pos;

Begin
  GetDirKpPos.Col := 0;
  GetDirKpPos.Row := 0;
  Case button Of 
    'A': GetDirKpPos.Col := 2;
    '^': GetDirKpPos.Col := 1;
    '>':
         Begin
           GetDirKpPos.Col := 2;
           GetDirKpPos.Row := 1;
         End;
    'v':
         Begin
           GetDirKpPos.Col := 1;
           GetDirKpPos.Row := 1;
         End;
    '<': GetDirKpPos.Row := 1;
  End;
End;

Function GetCost(code: String;
                 NumRobots: int64;
                 cache: TStringHashMap): int64;

Var totalCost: int64;
  Cost: int64;
  startChar, targetChar: char;
  startPos, targetPos: Pos;
Begin
  startChar := 'A';
  startPos := GetDirKpPos(startChar);
  totalCost := 0;
  For targetChar In code Do
    Begin
      If numRobots > 0 Then
        Begin
          totalCost := totalCost +
                       GetEntryKeyPressCount(startChar,
                       targetChar,
                       numRobots-1,
                       @GetDirKpStepPresses,
                       cache);
        End
      Else
        Begin
          targetPos := GetDirKpPos(targetChar);
          cost := PosDiff(startPos, targetPos);
          totalCost := totalCost + cost;
          // WriteLn('At NumRobots ', NumRobots, ' so, startchar:', startChar,
          //' ',postostring(startpos),
          // ', targetchar:', targetchar,' ', posToString(targetpos),
          //' (', cost, ', ', totalcost, ')') ;
        End;
      startPos := targetPos;
      startChar := targetChar;
    End;
  getCost := totalCost;
End;

Function GetPermutations(raw: String; cache: TStringHashMap): StringArray;

Var 
  cacheEntry: TStringArrayCacheEntry;
  ChildPermutations: StringArray;
  NumPermutations, Idx, Idx2: Integer;
  //LogPrefix: string;
  Ch: string;
Begin
  //logprefix := StringOfChar(' ', raw.length);

  If raw.length = 0 Then
    Begin
      setlength(ChildPermutations,0);
      GetPermutations := ChildPermutations;
      exit();
    End;
  If cache.contains(raw) Then
    Begin
      GetPermutations := TStringArrayCacheEntry(cache[raw]).Get();
      exit();
    End;

  //writeln(logprefix, 'looking for ', raw);
  Case raw.length Of 
    1: NumPermutations := 1;
    2: NumPermutations := 2;
    3: NumPermutations := 6;
    4: NumPermutations := 24;
    otherwise raise Exception.Create('unknown length: ' + raw)
  End;

  cacheEntry := TStringArrayCacheEntry.create(NumPermutations);

  If raw.length = 1 Then
    Begin
      cacheEntry.SetAt(0, raw);
    End
  Else
    Begin
      For idx := 0 To raw.length-1 Do
        Begin
          Ch := raw.substring(idx,1);
          //writeln(logprefix, idx, ': ', ch);
          ChildPermutations := GetPermutations(raw.substring(0,idx) + raw.
                               substring(idx+1), cache);
          For Idx2 := 0 To length(ChildPermutations)-1 Do
            Begin
              // writeln(logprefix, idx, ': ', idx2, ': ', ch, ' - ',
              // idx * length(childpermutations) + idx2,
              // ' - ', ch + childpermutations[idx2]);
              cacheEntry.SetAt(idx * length(childpermutations) + idx2,
              ch + childpermutations[idx2]);
            End;
        End;
    End;

  cache[raw] := cacheEntry;
  GetPermutations := cacheEntry.get();
End;


(* Generic Keypad *)
Function GetKpPresses (StartPos : Pos;
                       EndPos : Pos;
                       Blank : Pos;
                       NumRobots: int64;
                       cache: TStringHashMap): String;

Var 
  KeyPressH,KeyPressV: char;
  KeyPressesH,KeyPressesV: String;
  FirstChar : String;
  Raw: String;
  Combinations: StringArray;
  AnOption, Option, CheapestOption: String;
  Cost, CheapestCost: int64;
Begin
  If (StartPos.Col = EndPos.Col) And (startPos.row = Endpos.row) Then
    Begin
      GetKpPresses := 'A';
      exit();
    End;
  If StartPos.Col > EndPos.Col Then
    Begin
      KeyPressH := '<';
    End
  Else
    If StartPos.Col < EndPos.Col Then
      Begin
        KeyPressH := '>';
      End;
  KeyPressesH := StringOfChar(KeyPressH, abs(StartPos.Col - EndPos.Col));

  If StartPos.Row < EndPos.Row Then
    Begin
      KeyPressV :=  'v';
    End
  Else
    If startpos.row > EndPos.Row Then
      Begin
        KeyPressV := '^';
      End;
  KeyPressesV := StringOfChar(KeyPressV, abs(StartPos.Row - EndPos.Row));

  FirstChar := '';

  If (EndPos.Col = Blank.Col) And (StartPos.Row = Blank.Row) Then
    Begin
      FirstChar := KeyPressesV.SubString(0,1);
      KeyPressesV := KeyPressesV.SubString(1);
    End;

  If (StartPos.Col = Blank.Col) And (EndPos.Row = Blank.Row) Then
    Begin
      FirstChar := KeyPressesH.SubString(0,1);
      KeyPressesH := KeyPressesH.SubString(1);
    End;

  Raw := KeyPressesV + KeyPressesH;

  // writeln('Raw: ', FirstChar + Raw,
  //         ' ', PosToString(startpos), PosToString(endpos),', at NumRobots ',
  // NumRobots);

  Combinations := GetPermutations(Raw, cache);
  CheapestCost := -1;
  CheapestOption := '';
  For Option In Combinations Do
    Begin
      AnOption := FirstChar + Option + 'A';
      Cost := GetCost(AnOption, NumRobots, cache);
      //writeln('  AnOption: ', AnOption, ' (', Cost, ')');
      If (Cost < CheapestCost) Or (CheapestCost < 0) Then
        Begin
          CheapestOption := AnOption;
          CheapestCost := Cost;
        End;
    End;
  //writeln(' Cheapest ', CheapestOption, ' with cost ', CheapestCost);
  GetKpPresses := CheapestOption;
End;

(* Numeric KeyPad *)

Function GetNumKpPos (button : String) : Pos;

Var ButtonNumber : int64;
Begin
  If button = 'A' Then
    Begin
      GetNumKpPos.Col := 2;
      GetNumKpPos.Row := 3;
      Exit();
    End;
  ButtonNumber := StrToInt(button);
  If ButtonNumber = 0 Then
    Begin
      ButtonNumber := -2;
    End;
  GetNumKpPos.Col := (abs(ButtonNumber)-1) Mod 3;
  GetNumKpPos.Row := Trunc((9-ButtonNumber) / 3);
End;

Function GetNumKpStepPresses (start : String;
                              target : String;
                              numRobots: int64;
                              cache: TStringHashMap): String;

Var 
  StartPos, EndPos: Pos;
Begin
  StartPos := GetNumKpPos(start);
  EndPos := GetNumKpPos(target);

  GetNumKpStepPresses := GetKpPresses(StartPos,
                         EndPos,
                         NumKpBlankPos,
                         NumRobots,
                         cache);
End;

(* Directional Keypad *)

Function GetDirKpStepPresses (start: String;
                              target: String;
                              numRobots: int64;
                              cache: TStringHashMap): String;

Var 
  StartPos, EndPos: Pos;
Begin
  StartPos := GetDirKpPos(start);
  EndPos := GetDirKpPos(target);

  GetDirKpStepPresses := GetKpPresses(StartPos,
                         EndPos,
                         DirKpBlankPos,
                         numRobots,
                         cache);
End;

(* Human Entry Aggregation *)

Function GetEntryKeyPressCount(startChar: char;
                               targetChar: char;
                               numRobots: int64;
                               getKeyPressFunc: TGetKeyPressFunc;
                               cache: TStringHashMap): int64;

Var KeyPressCount, cacheValue: Int64;
  keyPresses: string;
  cacheKey: string;
  innerStartChar, innerTargetChar: char;
Begin
  cacheKey := startChar + ',' + targetChar + ':' + IntToStr(numRobots);

  If cache.contains(cacheKey) Then
    Begin
      cacheValue := TInt64CacheEntry(cache[cacheKey]).GetCost();
      //writeln('Got from cache: ', cacheKey, ' = ', cacheValue);
      GetEntryKeyPressCount := cacheValue;
      exit()
    End;

  KeyPresses := getKeyPressFunc(startChar, targetChar, numRobots, cache);
  // If (numRobots=0) Then
  //   Begin
  //     write(keypresses);
  //   End;
  If numRobots = 0 Then
    Begin
      KeyPressCount := KeyPresses.Length;
    End
  Else
    Begin
      innerStartChar := 'A';
      KeyPressCount := 0;
      For innerTargetChar In Keypresses Do
        Begin
          KeyPressCount := KeyPressCount +
                           GetEntryKeyPressCount(
                           innerStartChar,
                           innerTargetChar,
                           numRobots-1,
                           @GetDirKpStepPresses,
                           cache);
          innerStartChar := innerTargetChar;
        End;
    End;
  //writeln('Storing to cache: ', cacheKey, ' = ', keyPressCount);
  cache[cacheKey] := TInt64CacheEntry.create(KeyPressCount);
  GetEntryKeyPressCount := KeyPressCount;
End;


Function GetHumanEntryKeyPressCount(code: String; numRobots: int64): Int64;

Var totalLength: Int64;
  startChar, targetChar: char;
  cache: TStringHashMap;
Begin
  startChar := 'A';
  totalLength := 0;
  cache := TStringHashMap.create();

  // writeln('====');
  // writeln(code);

  For targetChar In code Do
    Begin
      totalLength := totalLength + GetEntryKeyPressCount(
                     startChar,
                     targetChar,
                     numRobots,
                     @GetNumKpStepPresses,
                     cache);
      startChar := targetChar;
    End;
  //  writeln();
  GetHumanEntryKeyPressCount := totalLength;
End;

Function GetComplexity(KeyPadEntry: String; NumRobots: int64): int64;

Var EntryCount: int64;
  KeypadNumber: int64;
Begin
  EntryCount := GetHumanEntryKeyPressCount(KeyPadEntry, NumRobots);
  KeypadNumber := StrToInt(KeyPadEntry.Substring(0,3));
  GetComplexity := EntryCount * KeypadNumber;
End;

Function GetTotalComplexity(
                            KeyPadEntries: String;
                            NumRobots: int64): int64;

Var KeyPadEntriesArr: TStringDynArray;
  KeyPadEntry: string;
  TotalComplexity: int64;
Begin
  KeyPadEntriesArr := SplitString(KeyPadEntries, LineEnding);
  TotalComplexity := 0;
  For KeyPadEntry In KeyPadEntriesArr Do
    Begin
      TotalComplexity := TotalComplexity +
                         GetComplexity(KeyPadEntry, NumRobots);
    End;
  GetTotalComplexity := TotalComplexity;
End;

(* Tests *)

Type 
  TDay21Tests = Class(TTestCase)
    Published 
      Procedure TestNumKpSingleMovement;
      Procedure TestDirKpSingleMovement;
      Procedure TestHumanEntryKeyPresses;
      Procedure TestSingleEntryComplexity;
      Procedure TestTotalComplexity;
      Procedure AoCTest;
  End;


Procedure TDay21Tests.TestNumKpSingleMovement;

Var cache: TStringHashMap;
Begin
  cache := TStringHashMap.create();
  CheckEquals('<A', GetNumKpStepPresses('A', '0', 0, cache), 'A to 0');
  CheckEquals('>A', GetNumKpStepPresses('0', 'A', 0, cache), '0 to A');
  CheckEquals('<A', GetNumKpStepPresses('3', '2', 0, cache), '3 to 2');
  CheckEquals('vA', GetNumKpStepPresses('8', '5', 0, cache), '8 to 5');
  CheckEquals('^A', GetNumKpStepPresses('1', '4', 0, cache), '1 to 4');
  CheckEquals('v>A', GetNumKpStepPresses('7', '5', 0, cache), '7 to 5');
  CheckEquals('>vA', GetNumKpStepPresses('1', '0', 0, cache), '1 to 0');
  CheckEquals('^<A', GetNumKpStepPresses('0', '1', 0, cache), '0 to 1');
  CheckEquals('v>>A', GetNumKpStepPresses('7', '6', 0, cache), '7 to 6');
  CheckEquals('vv<<A', GetNumKpStepPresses('9', '1', 0, cache), '9 to 1');
  CheckEquals('^^^<<A', GetNumKpStepPresses('A', '7', 0, cache), 'A to 7');
End;

Procedure TDay21Tests.TestDirKpSingleMovement;

Var cache: TStringHashMap;
Begin
  cache := TStringHashMap.create();
  CheckEquals('<A', GetDirKpStepPresses('A', '^', 0, cache), 'A to ^');
  CheckEquals('vA', GetDirKpStepPresses('A', '>', 0, cache), 'A to >');
  CheckEquals('<A', GetDirKpStepPresses('>', 'v', 0, cache), '> to <');
  CheckEquals('<A', GetDirKpStepPresses('v', '<', 0, cache), 'v to <');
End;

Procedure TDay21Tests.TestHumanEntryKeyPresses;
Begin
  CheckEquals(68, GetHumanEntryKeyPressCount('029A', 2), '029A');
  CheckEquals(60, GetHumanEntryKeyPressCount('980A', 2), '980A');
  CheckEquals(68, GetHumanEntryKeyPressCount('179A', 2), '179A');
  CheckEquals(64, GetHumanEntryKeyPressCount('456A', 2), '456A');
  CheckEquals(64, GetHumanEntryKeyPressCount('379A', 2), '379A');
  CheckEquals(164, GetHumanEntryKeyPressCount('029A', 3), '029A');
  CheckEquals(146, GetHumanEntryKeyPressCount('980A', 3), '980A');
  CheckEquals(164, GetHumanEntryKeyPressCount('179A', 3), '179A');
  CheckEquals(162, GetHumanEntryKeyPressCount('456A', 3), '456A');
  CheckEquals(156, GetHumanEntryKeyPressCount('379A', 3), '379A');
End;

Procedure TDay21Tests.TestSingleEntryComplexity;
Begin
  CheckEquals(1972 (*68*29*), GetComplexity('029A', 2));
  CheckEquals(58800 (*60*980*), GetComplexity('980A', 2));
  CheckEquals(12172 (*68*179*), GetComplexity('179A', 2));
  CheckEquals(29184 (*64*456*), GetComplexity('456A', 2));
  CheckEquals(24256 (*64*379*), GetComplexity('379A', 2));
End;

Procedure TDay21Tests.TestTotalComplexity;
Begin
  CheckEquals(126384, GetTotalComplexity('029A' + LineEnding +
              '980A' + LineEnding +
              '179A' + LineEnding +
              '456A' + LineEnding +
              '379A', 2), 'AoC Sample');
End;

Procedure TDay21Tests.AoCTest;
Begin

End;

Procedure RegisterTests;
Begin
  TestFramework.RegisterTest(TDay21Tests.Suite);
End;

Begin
  RegisterTests;
  RunRegisteredTests(rxbHaltOnFailures);
End.
