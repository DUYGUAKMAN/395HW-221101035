with Ada.Text_IO;
with Ada.Integer_Text_IO;
use Ada.Text_IO;
use Ada.Integer_Text_IO;

procedure Calculator is

   type Token_Type is (Number, Plus, Minus, Times, Divide, Open_Paren, Close_Paren, End_Of_Input, Invalid);

   type Token is record
      Kind  : Token_Type;
      Value : Integer := 0;
   end record;

   type Token_Array is array (1 .. 100) of Token;
   Tokens : Token_Array;

   Token_Count   : Natural := 0;
   Token_Index   : Natural := 1;
   Paren_Balance : Integer := 0;

   -- Tokenize: converts the input string into tokens.
   function Tokenize(Input : String) return Boolean is
      Index : Natural := Input'First;
   begin
      Token_Count := 0;
      Paren_Balance := 0;

      while Index <= Input'Last loop
         declare
            C : Character := Input(Index);
         begin
            if C = ' ' then
               Index := Index + 1;
            elsif C in '0' .. '9' then
               declare
                  Num : Integer := 0;
               begin
                  while (Index <= Input'Last) and then (Input(Index) in '0' .. '9') loop
                     Num := Num * 10 + (Character'Pos(Input(Index)) - Character'Pos('0'));
                     Index := Index + 1;
                  end loop;
                  Token_Count := Token_Count + 1;
                  Tokens(Token_Count).Kind := Number;
                  Tokens(Token_Count).Value := Num;
                  -- Already advanced Index, so do not increment here.
               end;
            elsif C = '+' then
               Token_Count := Token_Count + 1;
               Tokens(Token_Count).Kind := Plus;
               Index := Index + 1;
            elsif C = '-' then
               Token_Count := Token_Count + 1;
               Tokens(Token_Count).Kind := Minus;
               Index := Index + 1;
            elsif C = '*' then
               Token_Count := Token_Count + 1;
               Tokens(Token_Count).Kind := Times;
               Index := Index + 1;
            elsif C = '/' then
               Token_Count := Token_Count + 1;
               Tokens(Token_Count).Kind := Divide;
               Index := Index + 1;
            elsif C = '(' then
               Token_Count := Token_Count + 1;
               Tokens(Token_Count).Kind := Open_Paren;
               Index := Index + 1;
               Paren_Balance := Paren_Balance + 1;
            elsif C = ')' then
               Token_Count := Token_Count + 1;
               Tokens(Token_Count).Kind := Close_Paren;
               Index := Index + 1;
               Paren_Balance := Paren_Balance - 1;
               if Paren_Balance < 0 then
                  Put_Line("Error: Unmatched closing parenthesis.");
                  return False;
               end if;
            else
               Put_Line("Error: Invalid character " & C);
               return False;
            end if;
         end;
      end loop;

      if Paren_Balance /= 0 then
         Put_Line("Error: Unmatched opening parenthesis.");
         return False;
      end if;

      Token_Count := Token_Count + 1;
      Tokens(Token_Count).Kind := End_Of_Input;
      return True;
   end Tokenize;

   -- Next_Token returns the current token and advances the index.
   function Next_Token return Token is
   begin
      if Token_Index > Token_Count then
         return (End_Of_Input, 0);
      end if;
      Token_Index := Token_Index + 1;
      return Tokens(Token_Index - 1);
   end Next_Token;

   -- Forward declaration for expression parsing.
   function Parse_Expression return Integer;

   function Parse_Factor return Integer is
      T : Token := Next_Token;
   begin
      if T.Kind = Number then
         return T.Value;
      elsif T.Kind = Open_Paren then
         declare
            Result : Integer := Parse_Expression;
            T2     : Token := Next_Token;
         begin
            if T2.Kind /= Close_Paren then
               Put_Line("Error: Unmatched parenthesis.");
               return 0;
            end if;
            return Result;
         end;
      else
         Put_Line("Error: Invalid expression.");
         return 0;
      end if;
   end Parse_Factor;

   function Parse_Term return Integer is
      Result : Integer := Parse_Factor;
      T : Token;
   begin
      loop
         T := Next_Token;
         case T.Kind is
            when Times =>
               Result := Result * Parse_Factor;
            when Divide =>
               declare
                  Divisor : Integer := Parse_Factor;
               begin
                  if Divisor = 0 then
                     Put_Line("Error: Division by zero.");
                     return 0;
                  end if;
                  Result := Result / Divisor;
               end;
            when others =>
               Token_Index := Token_Index - 1;
               exit;
         end case;
      end loop;
      return Result;
   end Parse_Term;

   function Parse_Expression return Integer is
      Result : Integer := Parse_Term;
      T : Token;
   begin
      loop
         T := Next_Token;
         case T.Kind is
            when Plus =>
               Result := Result + Parse_Term;
            when Minus =>
               Result := Result - Parse_Term;
            when others =>
               Token_Index := Token_Index - 1;
               exit;
         end case;
      end loop;
      return Result;
   end Parse_Expression;

begin
   loop
      Put("Enter infix expression (or 'exit'): ");
      declare
         Input : String (1 .. 100);
         Last  : Natural;
      begin
         Get_Line(Input, Last);
         if Input(1 .. Last) = "exit" then
            Put_Line("Goodbye!");
            exit;
         end if;
         Token_Index := 1;
         if Tokenize(Input(1 .. Last)) then
            Token_Index := 1;
            Put("Result: ");
            Put(Integer'Image(Parse_Expression));
            New_Line;
         else
            Put_Line("Invalid expression.");
         end if;
      end;
   end loop;
end Calculator;
