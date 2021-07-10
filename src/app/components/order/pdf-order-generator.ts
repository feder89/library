import { runInThisContext } from "vm";
import { Utils } from "src/app/util/utils";
const orderHeaders = [
  { id: 'isbn', name: 'ISBN', width: 120 },
  { id: 'title', name: 'Titolo', width: 280 },
  { id: 'publishername', name: 'Casa Editrice', width: 120 },
  { id: 'quantity', name: 'Quantità', width: 75 },
];
const remindHeaders = [
  { id: 'codice_isbn', name: 'ISBN', width: 120 },
  { id: 'titolo', name: 'Titolo', width: 280 },
  { id: 'ce_nome', name: 'Casa Editrice', width: 120 },
  { id: 'quantity', name: 'Quantità', width: 75 },
];

const booklistHeaders = [
  { id: 'isbn', name: 'ISBN', width: 110 },
  { id: 'titolo', name: 'Titolo', width: 170 },
  { id: 'casa_editrice', name: 'Casa Editrice', width: 140 },
  { id: 'materia', name: 'Materia', width: 70 },
  { id: 'tomi', name: 'Tomi', width: 60 },
  { id: 'cd', name: 'CD', width: 60 },
  { id: 'cedola', name: 'Cedola', width: 70 },
  { id: 'prezzo', name: 'Prezzo €', width: 70 },
  { id: 'firma', name: 'Firma per consegna', width: 150 }
];


export class PDFOrderGenerator {
  private jsPDF;
  private order;
  constructor(jspdf) {
    this.jsPDF = jspdf;
  }
  public generatePDFOrder(order) {
    this.order = order;
    console.log(this.order.bookings[0].publishername);
    const address = (this.order.distributore.citta ? this.order.distributore.citta : '') + ' - ' +
      (this.order.distributore.provincia ? this.order.distributore.provincia : '');
    this.jsPDF.setFontSize(10);
    this.jsPDF.text(40, 40, this.order.sender.name);
    this.jsPDF.text(40, 52, this.order.sender.address);
    this.jsPDF.text(40, 64, this.order.sender.city);
    this.jsPDF.text(40, 76, this.order.sender.iva);
    this.jsPDF.text(420, 90, this.order.distributore.nome);
    this.jsPDF.text(420, 102, this.order.distributore.indirizzo ? this.order.distributore.indirizzo : '');
    this.jsPDF.text(420, 114, address);
    this.jsPDF.text(420, 126, 'P. IVA ' + (this.order.distributore.iva ? this.order.distributore.iva : ''));
    this.jsPDF.text(40, 175, this.setProtocol() + this.setDate(order.orderInfo.data));
    this.jsPDF.setFontStyle('bold');
    this.jsPDF.text(40, 195, 'OGGETTO: Ordine libri');
    this.jsPDF.setFontSize('');
    this.jsPDF.table(40, 240,
      this.stringifyObject(this.order.bookings),
      this.createHeaders(orderHeaders),
      { autoSize: false, fontSize: 9 });
    const dt = new Date();
    let filename = dt.toLocaleDateString().replace('/', '-');
    filename += '_' + dt.toLocaleTimeString().replace(':', '_');
    this.jsPDF.save(filename + '.pdf');

  }

  private setProtocol() {
    const year = new Date().getFullYear();
    return 'Protocollo n. ' + year + '/' + this.order.protocol;
  }

  private setDate(dt) {
    return ' del ' + new Utils().formatDatetime(dt.toString());
  }

  private stringifyObject(arr: any[]) {
    let res: any[] = [];
    arr.forEach(el => {
      res.push(Object.assign({ height: 0.2 }, {
        isbn: el.isbn,
        title: el.title,
        quantity: el.quantity.toString(),
        publishername: el.publishername
      }));
    });
    return res;
  }

  private stringifyRemindObject(arr: any[]) {
    let res: any[] = [];
    arr.forEach(el => {
      res.push(Object.assign({ height: 0.2 }, {
        codice_isbn: el.codice_isbn,
        titolo: el.titolo,
        quantity: el.quantity.toString(),
        ce_nome: el.ce_nome
      }));
    });
    return res;
  }

  private createHeaders(keys) {
    let result = [];
    for (let i = 0; i < keys.length; i += 1) {
      result.push({
        id: keys[i].id,
        name: keys[i].id,
        prompt: keys[i].name,
        width: keys[i].width,
        height: 0.2,
        align: 'center',
        padding: 0
      });
    }
    return result;
  }

  public generateBookListPDF(books) {
    this.jsPDF.setFontSize(10);
    this.jsPDF.text(40, 40, books.sender.name);
    this.jsPDF.text(40, 52, books.sender.address);
    this.jsPDF.text(40, 64, books.sender.city);
    this.jsPDF.text(40, 76, books.sender.iva);
    this.jsPDF.text(40, 88, books.sender.email);
    this.jsPDF.text(420, 40, 'SUDENTE: ' + books.student.nome + ' ' + books.student.cognome);
    this.jsPDF.text(420, 52, 'SCUOLA: ' + books.student.tipo + ',' + books.student.scuola);
    this.jsPDF.text(420, 64, 'CLASSE: ' + books.student.classe);
    this.jsPDF.text(420, 76, 'DATA PRENOTAZIONE: ' + books.student.data);
    this.jsPDF.text(40, 120, 'NUMERO FODERATURE :');
    this.jsPDF.table(40, 150,
      books.bookings,
      this.createHeaders(booklistHeaders),
      { autoSize: false, fontSize: 9 });
    const dt = new Date();
    let filename = books.student.nome + '_' + books.student.cognome;
    this.jsPDF.save(filename + '.pdf');
  }

  public generatePDFRemind(sender, order, wholsaler) {
    const address = (wholsaler.citta ? wholsaler.citta : '') + ' - ' +
      (wholsaler.provincia ? wholsaler.provincia : '');
    this.jsPDF.setFontSize(10);
    this.jsPDF.text(40, 40, sender.name);
    this.jsPDF.text(40, 52, sender.address);
    this.jsPDF.text(40, 64, sender.city);
    this.jsPDF.text(40, 76, sender.iva);
    this.jsPDF.text(420, 90, wholsaler.nome);
    this.jsPDF.text(420, 102, wholsaler.indirizzo ? wholsaler.indirizzo : '');
    this.jsPDF.text(420, 114, address);
    this.jsPDF.text(420, 126, 'P. IVA ' + (wholsaler.iva ? wholsaler.iva : ''));
    this.jsPDF.setFontStyle('bold');
    this.jsPDF.text(40, 165, 'OGGETTO: Sollecito ordini pregressi');
    this.jsPDF.setFontStyle('normal');
    this.jsPDF.setFontSize('9');
    let height: number = 0;
    for (let i = 0; i < order.length; i++) {
      const tbHgt: number = 220 + height;
      const txtHgt: number = 210 + height;
      this.jsPDF.text(40, txtHgt, 'Ordine n.' + order[i].id_ordine + this.setDate(order[i].data));
      this.jsPDF.table(40, tbHgt,
        this.stringifyRemindObject(order[i].books),
        this.createHeaders(remindHeaders),
        { autoSize: false, fontSize: 9 });
      height +=30+ (19* order[i].books.length);
    }

    const dt = new Date();
    let filename = dt.toLocaleDateString().replace('/', '-');
    filename += '_' + dt.toLocaleTimeString().replace(':', '_');
    this.jsPDF.save(filename + '.pdf');

  }

}
