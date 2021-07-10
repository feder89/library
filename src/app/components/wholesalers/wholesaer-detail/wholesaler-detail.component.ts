import { Component, OnInit, Input, SimpleChanges, OnChanges } from '@angular/core';
import { Wholesaler } from 'src/app/interfaces/wholesaler';
import { Utils } from 'src/app/util/utils';
import { WholesalerService } from 'src/app/services/wholesaler.service';
import { WholesalersComponent } from '../wholesalers.component';
import { AppComponent } from 'src/app/app.component';

@Component({
  selector: 'app-wholesaler-detail',
  templateUrl: './wholesaler-detail.component.html',
  styleUrls: ['./wholesaler-detail.component.css']
})
export class WholesalerDetailComponent implements OnInit, OnChanges {
  private mapper: Utils = new Utils();
  @Input() wholesalerId: number;
  public wholesaler: Wholesaler;

  constructor(private wholesalerService: WholesalerService,
    private app: AppComponent,
    private wholesalerComponent: WholesalersComponent) { }

  ngOnInit() {
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['wholesalerId'] && changes['wholesalerId'].currentValue != null) {
      this.loadWholesalerInfo(changes['wholesalerId'].currentValue);
    } else {
      this.initWholesaler();
    }
  }

  private initWholesaler(): void {
    this.wholesaler = {
      id: null,
      nome: '',
      iva: '',
      indirizzo: '',
      citta: '',
      provincia: '',
      mail: '',
      telefono: '',
      cap: ''
    };
  }

  private loadWholesalerInfo(idWholesaler: number): void {
    this.wholesalerService.getWholesalers(idWholesaler).subscribe(res => {
      this.wholesaler = res[0];
    });
  }

  public save(): void {
    if (this.wholesalerId != null) {
      this.updateWholesaler();
    } else {
      this.insertWholesaler();
    }
  }

  private updateWholesaler(): void {
    this.wholesalerService.updateWholesaler(this.wholesaler)
      .subscribe(
        res => {
          this.app.handleToastMessages('success', 'Completato', 'Distributore modificato');
          this.wholesalerComponent.displayDetailDialog = false;
        },
        error => {
          this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
        }
      );
  }

  private insertWholesaler(): void {
    this.wholesalerService.createWholesaler(this.mapper.mapperWholesalerToBeInserted(this.wholesaler)).subscribe(
      res => {
        this.app.handleToastMessages('success', 'Completato', 'Distributore creato');
        this.wholesalerComponent.displayDetailDialog = false;
      },
      error => {
        this.app.handleToastMessages('error', 'Messaggio di errore', 'Operazione fallita');
      }
    );
  }

}
