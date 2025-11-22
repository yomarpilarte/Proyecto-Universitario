using iTextSharp.text;
using iTextSharp.text.pdf;

namespace Viajes.Models.Helpers
{
    public class Pie_de_pagina : PdfPageEventHelper
    {

        private readonly Font fontPie = FontFactory.GetFont(FontFactory.HELVETICA_OBLIQUE, 8, BaseColor.Gray);

        public override void OnEndPage(PdfWriter writer, Document document)
        {
            var cb = writer.DirectContent;
            var fecha = DateTime.Now.ToString("dd/MM/yyyy HH:mm");
            var texto = new Phrase($"Sistema de Gestión de Gasto  |  Página {writer.PageNumber}  |  Generado: {fecha}", fontPie);

            ColumnText.ShowTextAligned(
                cb,
                Element.ALIGN_CENTER,
                texto,
                (document.Left + document.Right) / 2,
                document.Bottom - 10,
                0
            );
        }


    }
}
