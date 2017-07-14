defmodule Attribrutex do
  @moduledoc """
  Public functions to manage custom fields
  """
  import Ecto.Query

  alias Attribrutex.CustomField

  @repo Attribrutex.RepoClient.repo

  @doc """
  Creates a new field for a module.

  If you need specify a context, in example, the custom field belongs
  to a specific user, you can use the opts to set a `context_id` and a
  `context_type`.

  ## Example

     Attribrutex.create_custom_field("location", :string, User)

  Now, the custom field belongs to the `User` model

  ## Context example

     Attribrutex.create_custom_field("location", :string, User, context_id: user.id, context_type: "User")

  Setting a context, you can make fields available only for an specific resource

  """
  def create_custom_field(key, type, module, opts \\ [])
  def create_custom_field(key, type, module, []) do
    attrs = %{
      key: key,
      field_type: type,
      fieldable_type: module_name(module)
    }

    insert_custom_field(attrs)
  end
  def create_custom_field(key, type, module, [context_id: context_id, context_type: context_type]) do
    attrs = %{
      key: key,
      field_type: type,
      fieldable_type: module_name(module),
      context_id: context_id,
      context_type: context_type
    }

    insert_custom_field(attrs)
  end


  defp insert_custom_field(attrs) do
    with changeset <- CustomField.changeset(%CustomField{}, attrs) do
      @repo.insert(changeset)
    end
  end

  @doc """
  List fields for a module, you can pass a map with a `context_id` and
  `context_type` to search by context.

  It allow to return the fields in different formats adding `mode` param 
  in the options. `nil` value will return the structs.

  ## Mode params:

  * `:keys` - Only return the key values for every entry.
  * `:fields` - Return a list of maps with `key` and `type` keys.

  """
  def list_custom_fields_for(module, opts \\ %{}) do
    module
    |> module_name
    |> custom_field_query(opts[:context_id], opts[:context_type])
    |> select_custom_fields(opts[:mode])
    |> @repo.all
  end

  defp custom_field_query(fieldable_type, nil, nil), do: from c in CustomField, where: c.fieldable_type == ^fieldable_type
  defp custom_field_query(fieldable_type, context_id, context_type) do
    from c in CustomField,
      where: c.fieldable_type == ^fieldable_type and
        c.context_id == ^context_id and
        c.context_type == ^context_type
  end

  defp select_custom_fields(query, nil), do: query
  defp select_custom_fields(query, :keys), do: from c in query, select: c.key
  defp select_custom_fields(query, :fields), do: from c in query, select: %{key: c.key, type: c.field_type}

  defp module_name(module), do: module |> Module.split |> List.last
end
