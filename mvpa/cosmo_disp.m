function cosmo_disp(x,varargin)
% converts data to a string representation
%
% cosmo_disp(x,opt)
%
% Inputs:
%   x              any type of data element (can be a dataset struct)
%   opt            Optional struct with fields
%     .threshold   If the number of values in an array along a dimension
%                  exceeds threshold, then an array is showed in summary
%                  style along that dimension. Default: 5
%     .edgeitems   When an array is shown in summary style, edgeitems sets
%                  the number of items at the beginning and end of the
%                  array to be shown (separated by '...' in rows and by ':'
%                  in columns).
%                  Default: 3
%     .precision   Numeric precision, indicating number of decimals after
%                  the floating point
%                  Default: 3
%     .strlen      Maximal string lenght, if a string is longer the
%                  beginning and end are shown separated by ' ... '.
%                  Default: 20
%     .depth       Maximum recursion depth
%                  Default: 6
%
% Side effect:     Calling this function caused the representation of x
%                  to be displayed.
%
%
% Examples:
%     % display a complicated data structure
%     x=struct();
%     x.a_cell={[],{'cell within cell',[1 2; 3 4]}};
%     x.small_matrix=[10 11 12; 13 14 15];
%     x.big_matrix=reshape(1:200,10,20);
%     x.huge=2^40;
%     x.tiny=2^-40;
%     x.a_string='hello world';
%     x.a_struct.another_struct.name='me';
%     x.a_struct.another_struct.func=@abs;
%     cosmo_disp(x);
%     > .a_cell
%     >   { [  ]  { 'cell within cell'  [ 1         2
%     >                                   3         4 ] } }
%     > .small_matrix
%     >   [ 10        11        12
%     >     13        14        15 ]
%     > .big_matrix
%     >   [  1        11        21  ...  171       181       191
%     >      2        12        22  ...  172       182       192
%     >      3        13        23  ...  173       183       193
%     >      :         :         :        :         :         :
%     >      8        18        28  ...  178       188       198
%     >      9        19        29  ...  179       189       199
%     >     10        20        30  ...  180       190       200 ]@10x20
%     > .huge
%     >   [ 1.1e+12 ]
%     > .tiny
%     >   [ 9.09e-13 ]
%     > .a_string
%     >   'hello world'
%     > .a_struct
%     >   .another_struct
%     >     .name
%     >       'me'
%     >     .func
%     >       @abs
%     %
%     cosmo_disp(x.a_cell)
%     > { [  ]  { 'cell within cell'  [ 1         2
%     >                                 3         4 ] } }
%     cosmo_disp(x.a_cell{2}{2})
%     > [ 1         2
%     >   3         4 ]
%
%     % illustrate recursion 'depth' argument
%     m={'hello'};
%     % make a cell in a cell in a cell in a cell ...
%     for k=1:10, m{1}=m; end;
%     cosmo_disp(m)
%     > { { { { { { <cell> } } } } } }
%     cosmo_disp(m,'depth',8)
%     > { { { { { { { { <cell> } } } } } } } }
%     cosmo_disp(m,'depth',Inf)
%     > { { { { { { { { { { { 'hello' } } } } } } } } } } }
%
%     % illustrate 'threshold' and 'edgeitems' arguments
%     cosmo_disp(num2cell('a':'k'))
%     > { 'a'  'b'  'c' ... 'i'  'j'  'k'   }@1x11
%     cosmo_disp(num2cell('a':'k'),'threshold',Inf)
%     > { 'a'  'b'  'c'  'd'  'e'  'f'  'g'  'h'  'i'  'j'  'k' }
%     cosmo_disp(num2cell('a':'k'),'edgeitems',2)
%     > { 'a'  'b' ... 'j'  'k'   }@1x11
%
%     % illustrate 'precision' argument
%     for p=1:2:7, cosmo_disp(pi*[1 2],'precision',p); end
%     > [ 3       6 ]
%     > [ 3.14      6.28 ]
%     > [ 3.1416      6.2832 ]
%     > [ 3.141593      6.283185 ]
%
%
% Notes:
%   - Unlike the builtin 'disp' function, this function shows the contents
%     of x using recursion. For example if a cell contains a struct, then
%     the contents of that struct is shown as well
%   - Limitations:
%     * no support for structures with more than two dimensions
%     * structs must be singleton (of size 1x1)
%     * character arrays must be of size 1xP
%   - A use case is displaying dataset structs
%
% NNO Jan 2014

    defaults.threshold=5;    % max #items before triggering summary style
    defaults.edgeitems=3;    % #items at edges in summary style
    defaults.precision=3;    % show floats with 3 decimals
    defaults.strlen=20;      % insert '...' with strings more than 20 chars
    defaults.depth=6;        % maximal depth
    defaults.show_size=false;% always show size of matrices

    opt=cosmo_structjoin(defaults,varargin);

    % get string representation of x
    s=disp_helper(x, opt);

    % print string representation of x
    disp(s);

function s=disp_helper(x, opt)
    % general helper function to get a string representation. Unlike the
    % main function this function returns a string, which makes it suitable
    % for recursion
    depth=opt.depth;
    if depth<=0
        s=surround_with(true,'<',class(x),'>',size(x));
        return
    end

    opt.depth=depth-1;

    if iscell(x)
        check_is_2d(x);
        s=cell2str(x,opt);
    elseif isnumeric(x) || islogical(x)
        check_is_2d(x);
        s=matrix2str(x,opt);
    elseif ischar(x)
        check_is_2d(x);
        s=string2str(x,opt);
    elseif isa(x, 'function_handle')
        s=function_handle2str(x,opt);
    elseif isstruct(x)
        check_is_singleton(x);
        s=struct2str(x,opt);
    else
        s=sprintf('<%s>',class(x));
    end

function check_is_2d(s)
    ndim=numel(size(s));
    if ndim~=2
        error('Element with %d dimensions, only 2 are supported',ndim);
    end

function check_is_singleton(s)
    n=numel(s);
    if n>1
        error('Non-singleton elements (found %d values) not supported',n);
    end

function y=strcat_(xs)
    if isempty(xs)
        y='';
        return
    end

    % all elements in xs are char
    [nr,nc]=size(xs);
    ys=cell(1,nc);

    % height of each row
    width_per_col=max(cellfun(@(x)size(x,2),xs),[],1);
    height_per_row=max(cellfun(@(x)size(x,1),xs),[],2);
    for k=1:nc
        xcol=cell(nr,1);
        width=width_per_col(k);
        row_pos=0;
        for j=1:nr
            height=height_per_row(j);
            if height==0
                continue;
            end

            x=xs{j,k};
            sx=size(x);
            to_add=[height width]-sx;

            % pad with spaces
            row_pos=row_pos+1;
            xcol{row_pos}=[[x repmat(' ',sx(1),to_add(2))];...
                        repmat(' ',to_add(1), width)];
        end
        ys{k}=char(xcol{1:row_pos});
    end
    y=[ys{:}];


function y=struct2str(x,opt)
    fns=fieldnames(x);
    n=numel(fns);
    r=cell(n*2,1);
    for k=1:n
        fn=fns{k};
        r{k*2-1}=['.' fn];
        d=disp_helper(x.(fn),opt);
        r{k*2}=[repmat(' ',size(d,1),2) d];
    end
    y=strcat_(r);




function s=function_handle2str(x,opt)
    s_with_quotes=string2str(func2str(x),opt);
    s=['@' s_with_quotes(2:(end-1))];


function s=string2str(x, opt)
    if ~ischar(x), error('expected a char'); end
    if size(x,1)>1, error('string has to be a single row'); end

    infix=' ... ';

    n=numel(x);
    if n>opt.strlen
        h=floor((opt.strlen-numel(infix))/2);
        x=[x(1:h), infix ,x(n+((1-h):0))];
    end
    s=['''' x ''''];


function s=cell2str(x, opt)
    % display a cell

    edgeitems=opt.edgeitems;
    threshold=opt.threshold;

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, edgeitems, threshold, 1);
    [c_pre, c_post]=get_mx_idxs(x, edgeitems, threshold, 2);

    part_idxs={{r_pre, r_post}, {c_pre, c_post}};

    nrows=numel([r_pre r_post])+~isempty(r_post);
    ncols=numel([c_pre c_post])+~isempty(c_post);

    sinfix=cell(nrows,ncols*2+1);
    for k=1:(ncols-1)
        sinfix{1,k*2+2}='  ';
    end

    cpos=1;
    for cpart=1:2
        col_idxs=part_idxs{2}{cpart};
        nc=numel(col_idxs);

        rpos=0;
        for rpart=1:2
            row_idxs=part_idxs{1}{rpart};

            nr=numel(row_idxs);
            if nr==0
                continue
            end
            for ci=1:nc
                col_idx=col_idxs(ci);
                trgc=cpos+ci*2;
                for ri=1:nr
                    row_idx=row_idxs(ri);
                    sinfix{rpos+ri,trgc}=disp_helper(x{row_idx,...
                                                             col_idx},opt);
                    if cpart==2 && ci==1 && nc>0
                        sinfix{rpos+ri,cpos+ci*2-1}=' ... ';
                    end
                end


                if rpart==2
                    max_length=max(cellfun(@numel,sinfix(:,trgc)));
                    spaces=repmat(' ',1,floor(max_length/2-1));
                    sinfix{rpos,cpos+ci*2}=[spaces ':'];
                end
            end
            rpos=rpos+nr+1;
        end
        cpos=cpos+nc*2;
    end

    show_size=opt.show_size || ~isempty(r_post) || ~isempty(c_post);
    s=surround_with(show_size,'{ ', strcat_(sinfix), ' }', size(x));



function pre_infix_post=surround_with(show_size, pre, infix, post, matrix_sz)
    % surround infix by pre and post, doing
    if show_size && prod(matrix_sz)~=1
        size_str=sprintf('x%d',matrix_sz);
        size_str(1)='@';
    else
        size_str='';
    end
    post=strcat_({repmat(' ',size(infix,1)-1,1); [post size_str]});
    pre_infix_post=strcat_({pre, infix, post});


function s=matrix2str(x,opt)
    % display a matrix
    edgeitems=opt.edgeitems;
    threshold=opt.threshold;
    precision=opt.precision;

    % get indices of rows and columns to show
    [r_pre, r_post]=get_mx_idxs(x, edgeitems, threshold, 1);
    [c_pre, c_post]=get_mx_idxs(x, edgeitems, threshold, 2);

    % data to be shown
    y=x([r_pre r_post],[c_pre c_post]);

    % convert to string
    s=num2str(y,precision);

    % number of characters in first and second dimension
    [nc_row,nc_col]=size(s);

    % see where each column is a space; that's a potential split point
    sp_col=sum(s==' ',1)==nc_row;

    % col_index has value k for characters in the k-th column, else zero
    col_index=zeros(1,nc_col);
    col_count=1;
    in_num=true;
    for k=1:nc_col
        if in_num
            if sp_col(k)
                col_count=col_count+1;
                in_num=false;

            else
                col_index(k)=col_count;
            end
        elseif ~sp_col(k)
            in_num=true;
            col_index(k)=col_count;
        end
    end

    % deal with rows
    row_blocks=cell(3,1);
    if isempty(r_post)
        row_blocks{1,1}=s;
    else
        % insert ':' for each column
        line=repmat(' ',1,nc_col);
        for k=1:max(col_index)
            idxs=find(col_index==k);
            median_pos=round(mean(idxs));
            line(median_pos)=':';
        end
        row_blocks{1}=s(1:edgeitems,:);
        row_blocks{2}=line;
        row_blocks{3}=s(edgeitems+(1:edgeitems),:);
    end

    % deal with columns
    row_and_col_blocks=cell(3,3);
    for row=1:3
        if isempty(c_post)
            row_and_col_blocks{row}=row_blocks{row};
        else
            % insert ' ... ' halfway each row
            pre_end=find(col_index==edgeitems,1,'last')+1;
            post_start=find(col_index==(edgeitems+1),1,'first')-1;

            r=row_blocks{row,1};
            if isempty(r)
                continue;
            end
            row_and_col_blocks{row,1}=r(:,1:pre_end);
            if row~=2
                row_and_col_blocks{row,2}=repmat(' ... ',size(r,1),1);
            end
            row_and_col_blocks{row,3}=r(:,post_start:end);
        end
    end

    show_size=opt.show_size || ~isempty(r_post) || ~isempty(c_post);
    s=surround_with(show_size,'[ ',strcat_(row_and_col_blocks),' ]',...
                                                                size(x));


function [pre,post]=get_mx_idxs(x, edgeitems, threshold, dim)
    % returns the first and last indices for showing an array along
    % dimension dim. If size(x,dim)<2*edgeitems, then pre has all the
    % indices, otherwise pre and post have the first and last edgeitems
    % indices, respectively
    n=size(x,dim);

    if n>max(threshold,2*edgeitems) % properly deal with Inf values
        pre=1:edgeitems;
        post=n-edgeitems+(1:edgeitems);
    else
        pre=1:n;
        post=[];
    end

