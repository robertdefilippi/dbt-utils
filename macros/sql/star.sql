{% macro star(from, relation_alias=False, except=[], regex=False, prefix='', suffix='') -%}
    {{ return(adapter.dispatch('star', 'dbt_utils')(from, relation_alias, except, regex, prefix, suffix)) }}
{% endmacro %}

{% macro default__star(from, relation_alias=False, except=[], regex=False, prefix='', suffix='') -%}
    {%- do dbt_utils._is_relation(from, 'star') -%}
    {%- do dbt_utils._is_ephemeral(from, 'star') -%}

    {#-- Prevent querying of db in parsing mode. This works because this macro does not create any new refs. #}
    {%- if not execute -%}
        {{ return('') }}
    {% endif %}

    {%- set include_cols = [] %}
    {%- set cols = adapter.get_columns_in_relation(from) -%}
    {%- set except = except | map("lower") | list %}
    {%- for col in cols -%}

        {%- if col.column | lower not in except -%}
            {% do include_cols.append(col.column) %}

        {%- endif %}
    {%- endfor %}


    {%- for col in include_cols if not regex %}

        {%- if relation_alias %}{{ relation_alias }}.{% else %}{%- endif -%}{{ adapter.quote(col)|trim }} as {{ adapter.quote(prefix ~ col ~ suffix)|trim }}
        {%- if not loop.last %},{{ '\n  ' }}{% endif %}

    {% else %}

        {%- set col = col.column | string -%}
        {%- if modules.re.match(regex, current_column, modules.re.IGNORECASE) -%}
            {%- if relation_alias %}{{ relation_alias }}.{% else %}{%- endif -%}{{ adapter.quote(col)|trim }} as {{ adapter.quote(prefix ~ col ~ suffix)|trim }}
            {%- if not loop.last %},{{ '\n  ' }}{% endif %}

      {%- endif -%}
    {%- endfor -%}

{%- endmacro %}
