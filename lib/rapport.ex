defmodule Rapport do

  @moduledoc """
  Documentation for Rapport.
  """
  alias Rapport.Report
  alias Rapport.Page

  @normalize_css File.read!(Path.join(__DIR__, "normalize.css"))
  @paper_css File.read!(Path.join(__DIR__, "paper.css"))
  @base_template File.read!(Path.join(__DIR__, "base_template.html.eex"))

  @doc """
    Creates a new report.

    Returns a Report struct.

    ## Options

    * `:template` - An optional EEx template for the report.
  """
  def new(template \\ "") do
    report_template = template_content(template)
    %Report{
      title: "Report",
      paper_size: :A4,
      rotation: :portrait,
      pages: [],
      template: report_template,
      padding: 10
    }
  end

  @doc """
    Adds a new page to a report.

    ## Options

    `:report` - A report struct that you want to add the page to.
    `:page_template` - An EEx template for the page
    `:fields` - A map with fields that must be assigned to the EEx template

  """
  def add_page(%Report{} = report, page_template, %{} = fields) do
    template = template_content(page_template)
    new_page = %Page{template: template, fields: fields}
    Map.put(report, :pages, [new_page | report.pages])
  end

  @doc """
    Sets the title of the report.
    This is the title of the generated html report.

    ## Options

    `:report` - The report you want to set the title for.
    `:title` - The new title
  """
  def set_title(%Report{} = report, title) when is_binary(title) do
    Map.put(report, :title, title)
  end

  @doc """
    Sets the paper size for the report.

    Allowed paper sizes are :A4, :A3, :A5, :half_letter, :letter,
    :legal, :junior_legal and :ledger

    ## Options

    `:report` - The report that you want set the paper size for.
    `:paper_size` - The paper size
  """
  def set_paper_size(%Report{} = report, paper_size) do
    validate_list(paper_size,
    [:A4, :A3, :A5, :half_letter, :letter,
    :legal, :junior_legal, :ledger], "Invalid paper size")
    Map.put(report, :paper_size, paper_size)
  end

  @doc """
    Sets the rotation for the report.

    Allowed rotations are :portrait and :landscape

    ## Options

    `:report` - The report that you want set the rotation for.
    `:rotation` - The rotation
  """
  def set_rotation(%Report{} = report, rotation) do
    validate_list(rotation, [:portrait, :landscape], "Invalid rotation")
    Map.put(report, :rotation, rotation)
  end

  @doc """
    Sets the padding (in millimeters) for the report.

    Allowed paddings are 10, 15, 20, 25 mm

    ## Options

    `:report` - The report that you want set the padding for.
    `:rotation` - The padding
  """
  def set_padding(%Report{} = report, padding) when is_integer(padding) do
    validate_list(padding, [10, 15, 20, 25], "Invalid padding")
    Map.put(report, :padding, padding)
  end

  @doc """
    Generates HTML for the report.

    ## Options

    `:report` - The report that you want to generate to HTML.
  """
  def generate_html(%Report{} = report) do
    paper_settings = paper_settings_css(report)
    pages = generate_pages(report.pages, report.padding)

    assigns = [
      title: report.title,
      paper_settings: paper_settings,
      normalize_css: @normalize_css,
      paper_css: @paper_css,
      pages: pages,
      report_template: report.template
    ]

    EEx.eval_string @base_template, assigns: assigns
  end

  #########################
  ### Private functions ###
  #########################

  defp generate_pages(pages, padding) when is_list(pages) do
    Enum.reverse(pages)
    |> Enum.map(fn(page) -> generate_page(page, padding) end)
    |> Enum.join
  end

  defp generate_page(p, padding) do
    EEx.eval_string wrap_page_with_padding(p.template, padding), assigns: p.fields
  end

  defp wrap_page_with_padding(template, padding) do
    padding_css = "padding-" <> Integer.to_string(padding) <> "mm"
    """
    <div class=\"sheet #{padding_css}\">
      #{template}
    </div>
    """
  end

  defp paper_settings_css(%Report{} = report) do
    paper_size = Atom.to_string(report.paper_size)
    rotation = Atom.to_string(report.rotation)
    if rotation == "portrait", do: paper_size, else: "#{paper_size} #{rotation}"
  end

  defp validate_list(what, list, msg) do
    if what not in list, do: raise ArgumentError, message: msg
  end

  defp template_content(template) do
    if (File.exists?(template)), do: File.read!(template), else: template
  end
end
