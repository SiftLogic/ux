% vim: set filetype=erlang shiftwidth=4 tabstop=4 expandtab tw=80:
%%% =====================================================================
%%% This library is free software; you can redistribute it and/or modify
%%% it under the terms of the GNU Lesser General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This library is distributed in the hope that it will be useful, but
%%% WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
%%% Lesser General Public License for more details.
%%%
%%% You should have received a copy of the GNU Lesser General Public
%%% License along with this library; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
%%% USA
%%%
%%% $Id$
%%%
%%% @copyright 2010-2011 Michael Uvarov
%%% @author Michael Uvarov <arcusfelis@gmail.com>
%%% =====================================================================

%%% @doc Functions for extraction UNIDATA.
%%%      UNIDATA is a part of The Unicode Character Database (UCD).
%%%      For character properties, casing behavior, default line-, word-,
%%%      cluster-breaking behavior, etc.
%%%      http://unicode.org/ucd/
%%%
%%%      This file calls ux_unidata_filelist.
%%%      ux_unidata_filelist contains the list of available files.
%%%      ux_unidata_filelist returns the anonymous function.
%%%      Fun extracts information from ETS table.
%%%      The ETS tables were generated by ux_unidata_store. 
%%%      ux_unidata_store is the owner of the list of ETS tables.
%%%      ux_unidata_store runs ux_unidata_parser, which runs one of
%%%      ux_unidata_parser_*.
%%%      ux_unidata_parser reads file and put information to the ETS table.
%%%
%%%      Each file with UNIDATA is parsed to the list of the ETS tables.
%%%      Fun can read from ETS table.
%%%      If ETS table will be deleted, then fun will be reloaded.
%%% @end
%%% @private


-module(ux_unidata).
-author('Uvarov Michael <arcusfelis@gmail.com>').
-export([get_source_file/1, get_test_file/1, open_test_file/1]).
-export([char_to_upper/1, char_to_lower/1, is_upper/1, is_lower/1,
        char_comment/1, char_type/1, ccc/1, 
        nfc_qc/1, nfd_qc/1, nfkc_qc/1, nfkd_qc/1, 
        is_comp_excl/1, is_compat/1, decomp/1, comp/2, comp/1,
        ducet/1, char_block/1, char_script/1,

        break_props/1, tertiary_weight/1]).

-include("ux.hrl").

-type ux_ccc() :: ux_types:ux_ccc().




priv_dir() ->
    case code:priv_dir(ux) of
        [_|_] = Res -> Res;
        _ -> "../priv"
    end.


%% Return path to directory with testing data files.
test_dir() ->
    case code:lib_dir(ux, testing) of
        [_|_] = Res -> Res;
        _ -> "../testing"
    end.


get_dir('ucd') -> priv_dir() ++ "/"  ?UNIDATA_VERSION  "/";
get_dir('uca') -> priv_dir() ++ "/"  ?UCADATA_VERSION  "/".


get_test_dir('ucd') -> test_dir() ++ "/"  ?UNIDATA_VERSION  "/";
get_test_dir('uca') -> test_dir() ++ "/"  ?UCADATA_VERSION  "/".


-spec get_source_file(Parser::atom()) -> string().
get_source_file('allkeys') ->
    get_dir('uca') ++ "/allkeys.txt.gz";
get_source_file('blocks') ->
    get_dir('ucd') ++ "/Blocks.txt";
get_source_file('scripts') ->
    get_dir('ucd') ++ "/Scripts.txt";
get_source_file('comp_exclusions') ->
    get_dir('ucd') ++ "/CompositionExclusions.txt";
get_source_file('norm_props') ->
    get_dir('ucd') ++ "/DerivedNormalizationProps.txt.gz";
get_source_file('unidata') ->
    get_dir('ucd') ++ "/UnicodeData.txt.gz";
get_source_file('grapheme_break_property') ->
    get_dir('ucd') ++ "/auxiliary/GraphemeBreakProperty.txt.gz";
get_source_file('word_break_property') ->
    get_dir('ucd') ++ "/auxiliary/WordBreakProperty.txt.gz".




get_test_file('normalization_test') ->
    get_test_dir('ucd') ++ "NormalizationTest.txt.gz";

get_test_file('collation_test_shifted') ->
    get_test_dir('uca') ++ "CollationTest/" 
                    % Slow, with comments.
%                   "CollationTest_SHIFTED.txt";
                    "CollationTest_SHIFTED_SHORT.txt.gz";

get_test_file('collation_test_non_ignorable') ->
    get_test_dir('uca') ++ "CollationTest/" 
%                   "CollationTest_NON_IGNORABLE.txt", 
                    % Fast version (data from slow version are equal).
                    "CollationTest_NON_IGNORABLE_SHORT.txt.gz";









get_test_file('grapheme_break_test') ->
    get_dir('ucd') ++ "/auxiliary/GraphemeBreakTest.txt.gz";
get_test_file('word_break_test') ->
    get_dir('ucd') ++ "/auxiliary/WordBreakTest.txt.gz".


open_test_file(Id) ->
    Filename = get_test_file(Id),
    ux_unidata_parser:open_file(Filename).



-spec char_to_lower(char()) -> char(); 
        (skip_check) -> fun().

char_to_lower(C) -> 
    func(unidata, to_lower, C).


-spec char_to_upper(char()) -> char(); 
        (skip_check) -> fun().

char_to_upper(C) -> 
    func(unidata, to_upper, C).


-spec is_lower(char()) -> boolean(); 
        (skip_check) -> fun().

is_lower(C) -> 
    func(unidata, is_lower, C).


-spec is_upper(char()) -> boolean(); 
        (skip_check) -> fun().

is_upper(C) -> 
    func(unidata, is_upper, C).


-spec char_type(C::char()) -> atom();
        (skip_check) -> fun().

char_type(C) -> 
    func(unidata, type, C).


-spec char_comment(C::char()) -> binary();
        (skip_check) -> fun().

char_comment(C) -> 
    func(unidata, comment, C).


-spec ccc(C::char()) -> ux_ccc();
        (skip_check) -> fun().

ccc(C) -> 
    func(unidata, ccc, C).



-spec nfc_qc(C::char()) -> y | n | m;
        (skip_check) -> fun().

nfc_qc(C) -> 
    func(norm_props, nfc_qc, C).


-spec nfd_qc(C::char()) -> y | n | m;
        (skip_check) -> fun().

nfd_qc(C) -> 
    func(norm_props, nfd_qc, C).


-spec nfkc_qc(C::char()) -> y | n | m;
        (skip_check) -> fun().

nfkc_qc(C) -> 
    func(norm_props, nfkc_qc, C).


-spec nfkd_qc(C::char()) -> y | n | m;
        (skip_check) -> fun().

nfkd_qc(C) -> 
    func(norm_props, nfkd_qc, C).


-spec is_compat(C::char()) -> boolean();
        (skip_check) -> fun().

is_compat(C) -> 
    func(unidata, is_compat, C).



-spec is_comp_excl(C::char()) -> boolean();
        (skip_check) -> fun().

is_comp_excl(C) -> 
    func(comp_exclusions, is_exclusion, C).


-spec ducet(list()) -> list() | atom();
        (skip_check) -> fun().

ducet(L) -> func(allkeys, ducet, L).


-spec comp(char(), char()) -> char() | false.

comp(C1, C2) -> 
    func(unidata, comp, {C1, C2}).

comp('skip_check') -> 
    F = func(unidata, comp, 'skip_check'),
    fun(C1, C2) ->
        F({C1, C2})
    end.
    


-spec decomp(char()) -> list();
        (skip_check) -> fun().

decomp(C) -> 
    func(unidata, decomp, C).


-spec char_block(C::char()) -> atom();
        (skip_check) -> fun().

char_block(C) -> 
    func(blocks, block, C).


-spec char_script(C::char()) -> atom();
        (skip_check) -> fun().

char_script(C) -> 
    func(scripts, script, C).


-spec break_props(atom()) -> fun().
break_props('grapheme') ->
    Name = 'grapheme_break_property',
    func(Name, Name, 'skip_check');

break_props('word') ->
    Name = 'word_break_property',
    func(Name, Name, 'skip_check').
    


func(Parser, Type, Value) -> 
    F = ux_unidata_filelist:get_source(Parser, Type),
    F(Value).


% Case or Kana Subtype
w3(C) when 16#FF67 >= C, C >= 16#FF6F -> small_narrow_katakana;
w3(C) when 16#FF71 >= C, C >= 16#FF9D -> narrow_katakana;
w3(C) when 16#FFA0 >= C, C >= 16#FFDF -> narrow_hangul;
w3(C) when 16#32D0 >= C, C >= 16#32FE -> circled_katakana;
w3(C) -> 
    case func(unidata, w3, C) of 
        false ->
            case is_upper(C) of
                true -> upper;
                false -> false end;
            
        Type -> type end.


% Decomposition Type
comp_tag(C) -> func(unidata, comp_tag, C).


% http://unicode.org/reports/tr10/#Tertiary_Weight_Table
tertiary_weight(C) ->
    Type = comp_tag(C),
    SubType = w3(C),

    case {Type, SubType} of
        {false,     false}                  -> 16#02;
        {wide,      false}                  -> 16#03;
        {compat,    false}                  -> 16#04;
        {font,      false}                  -> 16#05;
        {circle,    false}                  -> 16#06;
                                      
        {false,     upper}                  -> 16#08;
        {wide,      upper}                  -> 16#09;
        {compat,    upper}                  -> 16#0A;
        {font,      upper}                  -> 16#0B;
        {circle,    upper}                  -> 16#0C;

        {small,     small_hiragana}         -> 16#0D;
        {false,     normal_hiragana}        -> 16#0E;
        {small,     small_katakana}         -> 16#0F;
        {narrow,    small_narrow_katakana}  -> 16#10;
        {false,     normal_katakana}        -> 16#11;
        {narrow,    narrow_katakana}        -> 16#12;
        {narrow,    narrow_hangul}          -> 16#12;
        {circle,    circled_katakana}       -> 16#13;
        {super,     false}                  -> 16#14;
        {sub,       false}                  -> 16#15;
        {vertical,  false}                  -> 16#16;
        {initial,   false}                  -> 16#17;
        {medial,    false}                  -> 16#18;
        {final,     false}                  -> 16#19;
        {isolated,  false}                  -> 16#1A;
        {noBreak,   false}                  -> 16#1D;
        {square,    false}                  -> 16#1C;
        {square,    upper}                  -> 16#1D;
        {super,     upper}                  -> 16#1D;
        {sub,       upper}                  -> 16#1D;
        {fraction,  false}                  -> 16#1E;
        {_,         _}                      -> 16#1F
    end.
